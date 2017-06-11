package Pcore::Dist::Build::PAR::Script;

use Pcore -class, -ansi;
use Pcore::Util::Text qw[add_num_sep];
use Pcore::Util::File::Tree;
use Archive::Zip qw[];
use PAR::Filter;
use Filter::Crypto::CryptFile;
use Pcore::Src::File;
use Config;
use Fcntl qw[:DEFAULT SEEK_END];

has dist   => ( is => 'ro', isa => InstanceOf ['Pcore::Dist'],       required => 1 );
has script => ( is => 'ro', isa => InstanceOf ['Pcore::Util::Path'], required => 1 );
has release => ( is => 'ro', isa => Bool,    required => 1 );
has crypt   => ( is => 'ro', isa => Bool,    required => 1 );
has clean   => ( is => 'ro', isa => Bool,    required => 1 );
has mod     => ( is => 'ro', isa => HashRef, required => 1 );

has tree => ( is => 'lazy', isa => InstanceOf ['Pcore::Util::File::Tree'], init_arg => undef );
has par_suffix     => ( is => 'lazy', isa => Str,     init_arg => undef );
has exe_filename   => ( is => 'lazy', isa => Str,     init_arg => undef );
has main_mod       => ( is => 'lazy', isa => HashRef, default  => sub { {} }, init_arg => undef );    # main modules, found during deps processing
has shared_objects => ( is => 'ro',   isa => HashRef, init_arg => undef );

sub _build_tree ($self) {
    return Pcore::Util::File::Tree->new;
}

sub _build_par_suffix ($self) {
    return $MSWIN ? '.exe' : q[];
}

sub _build_exe_filename ($self) {
    my $filename = $self->script->filename_base;

    my @attrs;

    if ( $self->release ) {
        push @attrs, $self->dist->version;
    }
    else {
        if ( $self->dist->id->{bookmark} ) {
            push @attrs, $self->dist->id->{bookmark};
        }
        else {
            push @attrs, $self->dist->id->{branch};
        }
    }

    push @attrs, 'x64' if $Config{archname} =~ /x64|x86_64/sm;

    return $filename . q[-] . join( q[-], @attrs ) . $self->par_suffix;
}

sub run ($self) {
    say qq[\nBuilding ] . ( $self->crypt ? $BLACK . $ON_GREEN . ' crypted ' : $BOLD . $WHITE . $ON_RED . q[ not crypted ] ) . $RESET . q[ ] . $BLACK . $ON_GREEN . ( $self->clean ? ' clean ' : ' cached ' ) . $RESET . qq[ "@{[$self->exe_filename]}" for $Config{archname}$LF];

    # add main script
    $self->_add_perl_source( $self->script->realpath->to_string, 'script/main.pl' );

    # add META.yml
    $self->tree->add_file( 'META.yml', P->data->to_yaml( { par => { clean => 1 } } ) ) if $self->clean;

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
            $member = $zip->addString(
                {   string           => $file->{content},
                    zipName          => $file->{path},
                    compressionLevel => 9,
                }
            );
        }
        else {
            $member = $zip->addFile(
                {   filename         => $file->{source_path},
                    zipName          => $file->{path},
                    compressionLevel => 9,
                }
            );
        }

        $member->unixFileAttributes( oct 666 );
    }

    my $zip_path = P->file->temppath( suffix => 'zip' );

    $zip->writeToFileNamed("$zip_path");

    # create parl executable
    my $parl_path = P->file->temppath( suffix => $self->par_suffix );

    print 'writing parl ... ';

    my $cmd = qq[parl -B -O"$parl_path" "$zip_path"];

    `$cmd` or die;

    say 'done';

    my $repacked_path = $self->_repack_parl( $parl_path, $zip );

    my $target_exe = $self->dist->root . 'data/' . $self->exe_filename;

    P->file->move( $repacked_path, $target_exe );

    P->file->chmod( 'rwx------', $target_exe );

    say 'final binary size: ' . $BLACK . $ON_GREEN . q[ ] . add_num_sep( -s $target_exe ) . q[ ] . $RESET . ' bytes';

    return;
}

sub _add_modules ($self) {

    # add full unicore database
    for my $lib ( reverse @INC ) {
        if ( -d "$lib/unicore/" ) {
            P->file->find(
                "$lib/unicore/",
                abs => 1,
                dir => 0,
                sub ($path) {
                    return if $path !~ /[.]p[lm]\z/sm;

                    $self->_add_module($path);

                    return;
                }
            );
        }
    }

    # add .pl, .pm
    for my $module ( grep {/[.](?:pl|pm)\z/sm} keys $self->mod->%* ) {
        my $found = $self->_add_module($module);

        $self->_error(qq[required module wasn't found: "$module"]) if !$found;
    }

    # add .pc (part of some Win32API modules)
    for my $module ( grep {/[.](?:pc)\z/sm} keys $self->mod->%* ) {
        my $found;

        for my $inc ( grep { !ref } @INC ) {
            if ( -f "$inc/$module" ) {
                $found = 1;

                $self->tree->add_file( "$Config{version}/$Config{archname}/$module", "$inc/$module" );

                last;
            }
        }

        $self->_error(qq[required module wasn't found: "$module"]) if !$found;
    }

    return;
}

# TODO add dso support for linux, look at Par::Packer/myldr/encode_append.pl
sub _add_shlib ($self) {
    die q[Currently on MSWIN platform is supported] if !$MSWIN;

    state $system_root = P->path( $ENV{SYSTEMROOT}, is_dir => 1 )->realpath;

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

    $dso->{ $perl_path->filename } = "$perl_path";

    # add found deps
    for my $filename ( sort keys $dso->%* ) {
        $self->tree->add_file( "shlib/$Config{archname}/$filename", $dso->{$filename} );

        say sprintf 'shlib added: %-30s %s', $filename, $dso->{$filename};
    }

    return;
}

sub _add_module ( $self, $module ) {
    $module = P->perl->module( $module, $self->dist->root . 'lib/' );

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
    $self->_add_dist( $ENV->pcore );

    for my $main_mod ( keys $self->main_mod->%* ) {
        next if $main_mod eq 'Pcore.pm' or $main_mod eq $self->dist->module->name;

        my $dist = Pcore::Dist->new($main_mod);

        $self->_error(qq[corrupted main module: "$main_mod"]) if !$dist;

        $self->_add_dist($dist);
    }

    # add current dist, should be added last to preserve share libs order
    $self->_add_dist( $self->dist );

    return;
}

sub _add_perl_source ( $self, $source, $target, $is_cpan_module = 0, $module = undef ) {
    my $src = P->file->read_bin($source);

    if ($module) {

        # detect pcore dist main module
        if ( $src->$* =~ /^use Pcore.+-dist.*;/m ) {    ## no critic qw[RegularExpressions::RequireDotMatchAnything]
            $self->main_mod->{$module} = [ $source, $target ];
        }

        # patch content for PAR compatibility
        $src = PAR::Filter->new('PatchContent')->apply( $src, $module );
    }

    $src = Pcore::Src::File->new(
        {   action      => $Pcore::Src::SRC_COMPRESS,
            path        => $target,
            is_realpath => 0,
            in_buffer   => $src,
            filter_args => {
                perl_compress_keep_ln => 1,
                perl_strip_comment    => 1,
                perl_strip_pod        => 1,
            },
        }
    )->run->out_buffer;

    # crypt sources, do not crypt CPAN modules
    if ( !$is_cpan_module && $self->crypt && ( !$module || $module ne 'Filter/Crypto/Decrypt.pm' ) ) {
        my $crypt = 1;

        # do not crypt modules, that belongs to the CPAN distribution
        if ( !$is_cpan_module && ( my $dist = Pcore::Dist->new( P->path($source)->dirname ) ) ) {
            $crypt = 0 if $dist->cfg->{cpan};
        }

        if ($crypt) {
            open my $crypt_in_fh, '<', $src or die;

            open my $crypt_out_fh, '+>', \my $crypted_src or die;

            Filter::Crypto::CryptFile::crypt_file( $crypt_in_fh, $crypt_out_fh, Filter::Crypto::CryptFile::CRYPT_MODE_ENCRYPTED() );

            close $crypt_in_fh or die;

            close $crypt_out_fh or die;

            $src = \$crypted_src;
        }
    }

    $self->tree->add_file( $target, $src );

    return;
}

sub _add_dist ( $self, $dist ) {
    if ( $dist->name eq $self->dist->name ) {

        # add main dist share
        $self->tree->add_dir( $dist->share_dir, 'share/' );

        # add main dist dist-id.json
        $self->tree->add_file( 'share/dist-id.json', P->data->to_json( $dist->id, readable => 1 ) );
    }
    else {

        # add dist share
        $self->tree->add_dir( $dist->share_dir, "lib/auto/share/dist/@{[ $dist->name ]}/" );

        # add dist-id.json
        $self->tree->add_file( "lib/auto/share/dist/@{[ $dist->name ]}/dist-id.json", P->data->to_json( $dist->id, readable => 1 ) );
    }

    say 'dist added: ' . $dist->name;

    return;
}

sub _repack_parl ( $self, $parl_path, $zip ) {
    print 'repacking parl ... ';

    my $src = P->file->read_bin($parl_path);

    my $in_len = length $src->$*;

    # cut magic string
    $src->$* =~ s/(.{4})\x0APAR[.]pm\x0A\z//sm;

    # unpack overlay length
    my $overlay_length = unpack 'N', $1;

    # extract overlay
    # src = raw exe header
    # overlay = files sections + par zip section + cache id string
    my $overlay = substr $src->$*, length( $src->$* ) - $overlay_length, $overlay_length, q[];

    # cut cache id, now overlay = files sections + par zip section
    $overlay =~ s/.{40}\x{00}CACHE\z//sm;

    my $parl_so_temp = P->file->tempdir;

    my $file_section = {};

    while (1) {
        last if $overlay !~ s/\AFILE//sm;

        my $filename_length = unpack( 'N', substr( $overlay, 0, 4, q[] ) ) - 9;

        substr $overlay, 0, 9, q[];

        my $filename = substr $overlay, 0, $filename_length, q[];

        my $content_length = unpack( 'N', substr( $overlay, 0, 4, q[] ) );

        my $content = substr $overlay, 0, $content_length, q[];

        if ( $filename =~ /[.](?:pl|pm)\z/sm ) {

            # compress perl sources
            $file_section->{$filename} = Pcore::Src::File->new(
                {   action      => $Pcore::Src::SRC_COMPRESS,
                    path        => $filename,
                    is_realpath => 0,
                    in_buffer   => \$content,
                    filter_args => {                            #
                        perl_compress         => 1,
                        perl_compress_keep_ln => 0,
                    },
                }
            )->run->out_buffer;
        }
        else {
            $file_section->{$filename} = \$content;
        }
    }

    my $path = P->file->temppath( suffix => $self->par_suffix );

    # write raw exe
    P->file->write_bin( $path, $src );

    # patch windows exe icon
    $self->_patch_icon($path);

    my $md5 = Digest::MD5->new;

    $md5->add( $src->$* );

    my $fh = P->file->get_fh( $path, O_RDWR );

    $fh->seek( 0, SEEK_END );

    my $exe_header_length = $fh->tell;

    # adding files sections
    for my $filename ( sort keys $file_section->%* ) {
        my $content = ref $file_section->{$filename} ? $file_section->{$filename} : P->file->read_bin( $file_section->{$filename} );

        $fh->print( 'FILE' . pack( 'N', length($filename) + 9 ) . sprintf( '%08x', Archive::Zip::computeCRC32( $content->$* ) ) . q[/] . $filename . pack( 'N', length $content->$* ) . $content->$* );

        $md5->add( $content->$* );
    }

    # addding par zip section, handle should be opened in r/w mode
    $zip->writeToFileHandle( $fh, 1 ) and die;

    # calculate par zip section hash
    for my $member ( sort { $a->fileName cmp $b->fileName } $zip->members ) {
        $md5->add( $member->fileName . $member->crc32String );
    }

    my $hash = $md5->hexdigest;

    # writing cache id
    $fh->print( pack( 'Z40', $hash ) . qq[\x00CACHE] );

    # writing overlay length
    $fh->print( pack( 'N', $fh->tell - $exe_header_length ) . "\x0APAR.pm\x0A" );

    my $out_len = $fh->tell;

    say 'done, ', $BLACK . $ON_GREEN . q[ ] . add_num_sep( $out_len - $in_len ) . q[ ] . $RESET . ' bytes';

    say 'hash: ' . $hash;

    # need to close fh before copy / patch file
    $fh->close;

    return $path;
}

sub _patch_icon ( $self, $path ) {

    # .ico
    # 4 layers, 16x16, 32x32, 16x16, 32x32
    # all layers 8bpp, 1-bit alpha, 256-slot palette

    if ($MSWIN) {
        state $init = !!require Win32::Exe;

        # path should be passed as plain string
        my $exe = Win32::Exe->new("$path");

        $exe->update( icon => $ENV->share->get('/data/par.ico') );
    }

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
## |    3 | 307                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 397                  | RegularExpressions::ProhibitCaptureWithoutTest - Capture variable used outside conditional                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 482, 485             | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 414, 420             | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
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
