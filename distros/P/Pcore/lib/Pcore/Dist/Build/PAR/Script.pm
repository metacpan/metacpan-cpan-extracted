package Pcore::Dist::Build::PAR::Script;

use Pcore -class, -ansi;
use Pcore::Util::Text qw[add_num_sep];
use Pcore::Util::File::Tree;
use Archive::Zip qw[];
use PAR::Filter;
use Config;
use Fcntl qw[:DEFAULT SEEK_END];

has dist    => ( required => 1 );    # InstanceOf ['Pcore::Dist']
has script  => ( required => 1 );    # InstanceOf ['Pcore::Util::Path']
has release => ( required => 1 );
has crypt   => ( required => 1 );
has clean   => ( required => 1 );
has gui     => ( required => 1 );
has mod     => ( required => 1 );    # HashRef

has tree         => ( is => 'lazy', init_arg => undef );    # InstanceOf ['Pcore::Util::File::Tree']
has par_suffix   => ( is => 'lazy', init_arg => undef );
has exe_filename => ( is => 'lazy', init_arg => undef );
has main_mod       => ( sub { {} }, is => 'lazy', init_arg => undef );    # HashRef, main modules, found during deps processing
has shared_objects => ( init_arg       => undef );                        # HashRef

sub _build_tree ($self) {
    return Pcore::Util::File::Tree->new;
}

sub _build_par_suffix ($self) {
    return $MSWIN ? '.exe' : $EMPTY;
}

sub _build_exe_filename ($self) {
    my $filename = $self->{script}->{filename_base};

    my @attrs;

    if ( $self->{release} ) {
        push @attrs, $self->{dist}->version;
    }
    else {
        if ( $self->{dist}->id->{bookmark} ) {
            push @attrs, $self->{dist}->id->{bookmark};
        }
        else {
            push @attrs, $self->{dist}->id->{branch};
        }
    }

    push @attrs, 'x64' if $Config{archname} =~ /x64|x86_64/sm;

    return $filename . q[-] . join( q[-], @attrs ) . $self->par_suffix;
}

sub run ($self) {
    say qq[\nBuilding ] . ( $self->{crypt} ? $BLACK . $ON_GREEN . ' crypted ' : $BOLD . $WHITE . $ON_RED . q[ not crypted ] ) . $RESET . $SPACE . $BLACK . $ON_GREEN . ( $self->{clean} ? ' clean ' : ' cached ' ) . $RESET . qq[ "@{[$self->exe_filename]}" for $Config{archname}\n];

    # add main script
    $self->_add_perl_source( $self->{script}->to_abs->{path}, 'script/main.pl' );

    # add META.yml
    $self->tree->add_file( 'META.yml', \P->data->to_yaml( { par => { clean => 1 } } ) ) if $self->{clean};

    # add modules
    print 'adding modules ... ';

    $self->_add_modules;

    say 'done';

    # process found distributions
    $self->_process_main_modules;

    # add shlib
    $self->_add_shlib;

    my $temp = $self->tree->write_to_temp;

    # create zipped par
    my $zip = Archive::Zip->new;

    for my $file ( values $self->tree->{files}->%* ) {
        my $member;

        if ( ref $file->{content} ) {
            $member = $zip->addString( {
                string           => $file->{content},
                zipName          => $file->{path},
                compressionLevel => 9,
            } );
        }
        else {
            $member = $zip->addFile( {
                filename         => $file->{source_path},
                zipName          => $file->{path},
                compressionLevel => 9,
            } );
        }

        $member->unixFileAttributes( oct 666 );
    }

    my $zip_path = P->file1->tempfile;

    $zip->writeToFileNamed( $zip_path->{path} );

    # create parl executable
    my $parl_path = P->file1->tempfile;

    print 'writing parl ... ';

    my $cmd = qq[parl -B -O"$parl_path" "$zip_path"];

    `$cmd` or die;

    say 'done';

    # patch windows exe icon
    $self->_patch_icon("$parl_path");

    # patch windows GUI
    $self->_patch_gui("$parl_path") if $self->{gui} && $MSWIN;

    my $target_exe = "$self->{dist}->{root}/data/" . $self->exe_filename;

    P->file->move( $parl_path, $target_exe );

    P->file->chmod( 'rwx------', $target_exe );

    say 'final binary size: ' . $BLACK . $ON_GREEN . $SPACE . add_num_sep( -s $target_exe ) . $SPACE . $RESET . ' bytes';

    return;
}

sub _add_modules ($self) {

    # add full unicore database
    for my $lib ( reverse @INC ) {
        for my $path ( ( P->path("$lib/unicore")->read_dir( max_depth => 0, abs => 1, is_dir => 0 ) // [] )->@* ) {
            next if $path !~ /[.]p[lm]\z/sm;

            $self->_add_module($path);
        }
    }

    my $not_found_modules;

    # add .pl, .pm
    for my $module ( grep {/[.](?:pl|pm)\z/sm} keys $self->{mod}->%* ) {
        my $found = $self->_add_module($module);

        push $not_found_modules->@*, $module if !$found;
    }

    # add .pc (part of some Win32API modules)
    for my $module ( grep {/[.](?:pc)\z/sm} keys $self->{mod}->%* ) {
        my $found;

        for my $inc ( grep { !ref } @INC ) {
            if ( -f "$inc/$module" ) {
                $found = 1;

                $self->tree->add_file( "$Config{version}/$Config{archname}/$module", "$inc/$module" );

                last;
            }
        }

        push $not_found_modules->@*, $module if !$found;
    }

    if ($not_found_modules) {
        $self->_error( q[required modules wasn't found: ] . join ', ', map {qq["$_"]} $not_found_modules->@* );
    }

    return;
}

# TODO add dso support for linux, look at Par::Packer/myldr/encode_append.pl
sub _add_shlib ($self) {
    die q[Currently on MSWIN platform is supported] if !$MSWIN;

    state $system_root = P->path( $ENV{SYSTEMROOT} )->to_abs;

    state $is_system_lib = sub ($path) {
        return $path =~ m[^\Q$system_root\E]smi ? 1 : 0;
    };

    my $find_dso = sub ( $dso, $so_path ) {
        my $out = `objdump -ax $so_path`;

        while ( $out =~ /^\s*DLL Name:\s*(\S+)/smg ) {
            my $so = $1;

            # find so in $PATH
            if ( my $path = P->file->where($so) ) {
                next if exists $dso->{$so};

                next if $is_system_lib->($path);

                $dso->{$so} = $path->to_string;

                __SUB__->( $dso, $path->to_string );
            }

            # so wasn't found in $PATH
            else {

                # try to find so in modules shared deps
                my $found;

                for my $mod_so_path ( values $self->{shared_objects}->%* ) {
                    if ( $mod_so_path =~ /\Q$so\E\z/sm ) {
                        $found = 1;

                        $dso->{$so} = $mod_so_path;

                        last;
                    }
                }

                $self->_error(qq["$so_path" dependency "$so" wasn't found]) if !$found;
            }
        }

        return;
    };

    # scan deps for perl executalbe and modules shared objects
    my $dso = {};

    for my $path ( $^X, values $self->{shared_objects}->%* ) {
        $find_dso->( $dso, $path );
    }

    # do not add perl deps, because they are already packed to parl
    $find_dso->( my $perl_dso = {}, $^X );

    delete $dso->@{ keys $perl_dso->%* };

    my $perl_path = P->path($^X);

    $dso->{ $perl_path->{filename} } = "$perl_path";

    # add found deps
    for my $filename ( sort keys $dso->%* ) {
        $self->tree->add_file( "shlib/$Config{archname}/$filename", $dso->{$filename} );

        say sprintf 'shlib added: %-30s %s', $filename, $dso->{$filename};
    }

    return;
}

sub _add_module ( $self, $module ) {
    $module = P->perl->module( $module, "$self->{dist}->{root}/lib" );

    # module wasn't found
    return if !$module;

    my $target;

    if ( my $auto_deps = $module->auto_deps ) {

        # module have auto deps
        $target = "$Config{version}/$Config{archname}/";

        for my $deps ( keys $auto_deps->%* ) {
            $self->{shared_objects}->{$deps} = $auto_deps->{$deps} if $auto_deps->{$deps} =~ /[.]$Config{dlext}\z/sm;

            $self->tree->add_file( $target . $deps, $auto_deps->{$deps} );
        }
    }
    else {
        $target = 'lib/';
    }

    # add .pm to the files tree
    $self->_add_perl_source( $module->path, $target . $module->name, $module->is_cpan_module, $module->name );

    return 1;
}

sub _process_main_modules ($self) {

    # add Pcore dist
    $self->_add_dist( $ENV->{pcore} );

    for my $main_mod ( keys $self->main_mod->%* ) {
        next if $main_mod eq 'Pcore.pm' or $main_mod eq $self->{dist}->module->name;

        my $dist = Pcore::Dist->new($main_mod);

        $self->_error(qq[corrupted main module: "$main_mod"]) if !$dist;

        $self->_add_dist($dist);
    }

    # add current dist, should be added last to preserve share libs order
    $self->_add_dist( $self->{dist} );

    return;
}

sub _add_perl_source ( $self, $source, $target, $is_cpan_module = 0, $module = undef ) {
    my $src = \P->file->read_bin($source);

    if ($module) {

        # detect pcore dist main module
        if ( $src->$* =~ /^use Pcore.+-dist.*;/m ) {    ## no critic qw[RegularExpressions::RequireDotMatchAnything]
            $self->main_mod->{$module} = [ $source, $target ];
        }

        # patch content for PAR compatibility
        $src = PAR::Filter->new('PatchContent')->apply( $src, $module );
    }

    my $encrypt = $self->{crypt};

    if ($encrypt) {

        # do not encrypt modules, that are located on CPAN
        if ($is_cpan_module) {
            $encrypt = 0;
        }

        # do not encrypt Filter::Crypto::Decrypt
        elsif ( $module && $module eq 'Filter/Crypto/Decrypt.pm' ) {
            $encrypt = 0;
        }

        # do not encrypt modules, that are belongs to Pcore CPAN distributions
        elsif ( !$is_cpan_module && ( my $dist = Pcore::Dist->new( P->path($source)->{dirname} ) ) ) {
            $encrypt = 0 if $dist->cfg->{cpan};
        }
    }

    $src = \P->src->compress(
        path   => $target,
        data   => $src->$*,
        filter => {
            perl_compress_keep_ln => 1,
            perl_strip_comment    => 1,
            perl_strip_pod        => 1,
            perl_encrypt          => $encrypt,
        }
    )->{data};

    $self->tree->add_file( $target, $src );

    return;
}

sub _add_dist ( $self, $dist ) {
    if ( $dist->name eq $self->{dist}->name ) {

        # add main dist share
        $self->tree->add_dir( $dist->{share_dir}, 'share' );

        # add main dist dist-id.yaml
        $self->tree->add_file( 'share/dist-id.yaml', \P->data->to_yaml( $dist->id ) );
    }
    else {

        # add dist share
        $self->tree->add_dir( $dist->{share_dir}, "lib/auto/share/dist/@{[ $dist->name ]}" );

        # add dist-id.yaml
        $self->tree->add_file( "lib/auto/share/dist/@{[ $dist->name ]}/dist-id.yaml", \P->data->to_yaml( $dist->id ) );
    }

    say 'dist added: ' . $dist->name;

    return;
}

sub _patch_icon ( $self, $path ) {

    # .ico
    # 4 layers, 16x16, 32x32, 16x16, 32x32
    # all layers 8bpp, 1-bit alpha, 256-slot palette

    if ($MSWIN) {
        require Win32::Exe;

        # path should be passed as plain string
        my $exe = Win32::Exe->new("$path");

        $exe->update( icon => $ENV->{share}->get('data/par.ico') );
    }

    return;
}

sub _patch_gui ( $self, $file ) {
    my ( $record, $magic, $signature, $offset, $size );

    open my $exe, '+<', $file or die $!;    ## no critic qw[InputOutput::RequireBriefOpen]

    binmode $exe or die $!;
    seek $exe, 0, 0 or die $!;

    # read IMAGE_DOS_HEADER structure
    read $exe, $record, 64 or die $!;
    ( $magic, $offset ) = unpack 'Sx58L', $record;

    die "$file is not an MSDOS executable file.\n" unless $magic == 0x5a4d;    # "MZ"

    # read signature, IMAGE_FILE_HEADER and first WORD of IMAGE_OPTIONAL_HEADER
    seek $exe, $offset, 0 or die $!;
    read $exe, $record, 4 + 20 + 2 or die $!;

    ( $signature, $size, $magic ) = unpack 'Lx16Sx2S', $record;

    die 'PE header not found' unless $signature == 0x4550;                     # "PE\0\0"

    die 'Optional header is neither in NT32 nor in NT64 format'
      unless ( $size == 224 && $magic == 0x10b )                               # IMAGE_NT_OPTIONAL_HDR32_MAGIC
      || ( $size == 240 && $magic == 0x20b );                                  # IMAGE_NT_OPTIONAL_HDR64_MAGIC

    # Offset 68 in the IMAGE_OPTIONAL_HEADER(32|64) is the 16 bit subsystem code
    seek $exe, $offset + 4 + 20 + 68, 0 or die $!;
    print {$exe} pack 'S', 2;                                                  # IMAGE_WINDOWS
    close $exe or die $!;

    return;
}

sub _error ( $self, $msg ) {
    say $BOLD . $GREEN . 'PAR ERROR: ' . $msg . $RESET;

    exit 5;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 305                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 397                  | NamingConventions::ProhibitAmbiguousNames - Ambiguously named variable "record"                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 416                  | ValuesAndExpressions::RequireNumberSeparators - Long number not separated with underscores                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::Build::PAR::Script

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
