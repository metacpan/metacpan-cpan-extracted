package Pcore::Util::Perl::Module;

use Pcore -class;
use Pcore::Util::Scalar qw[is_ref];
use Config;

has name    => ( is => 'lazy' );    # Maybe [Str], Module/Name.pm
has content => ( is => 'lazy' );    # ScalarRef
has path    => ( is => 'lazy' );    # Maybe [Str], /absolute/path/to/lib/Module/Name.pm
has lib     => ( is => 'lazy' );    # Maybe [Str], /absolute/path/to/lib/

has is_cpan_module => ( is => 'lazy', init_arg => undef );    # module has lib and lib is a part of pcore dist
has is_crypted     => ( is => 'lazy', init_arg => undef );    # module is crypted with Filter::Crypto
has abstract       => ( is => 'lazy', init_arg => undef );    # abstract from POD
has version        => ( is => 'lazy', init_arg => undef );    # Maybe [ InstanceOf ['version'] ], parsed version
has auto_deps      => ( is => 'lazy', init_arg => undef );    # Maybe [HashRef]

around new => sub ( $orig, $self, $module, @inc ) {
    if ( ref $module eq 'SCALAR' ) {

        # module content is passed as ScalarRef
        return $self->$orig( {
            name    => undef,
            path    => undef,
            lib     => undef,
            content => $module,
        } );
    }
    else {

        # if module is not contains .pl or .pm suffixes - this is Package::Name
        # convert Package::Name to Module/Name.pm
        my $suffix = substr $module, -3, 3;

        if ( $suffix ne '.pm' && $suffix ne '.pl' ) {
            $module =~ s[::][/]smg;

            $module .= '.pm';
        }

        if ( -f $module ) {

            # module was found at full path
            return $self->$orig( { path => P->path($module)->to_abs } );
        }
        else {

            # try to find module in @inc, items can be path objects
            for my $lib (@inc) {
                return $self->$orig( { lib => P->path($lib)->to_abs, name => $module } ) if -f "$lib/$module";
            }

            # try to find module in @INC
            for my $lib (@INC) {
                next if is_ref $lib;

                return $self->$orig( { lib => P->path($lib)->to_abs, name => $module } ) if -f "$lib/$module";
            }
        }
    }

    return;
};

# CLASS METHODS
sub lib_is_dist ( $self, $lib ) {
    if ( -d "$lib/auto/" ) {
        return 0;
    }
    else {
        return Pcore::Dist->dir_is_dist_root( $self->lib . '/../' ) ? 1 : 0;
    }
}

sub _split_path ($self) {
    if ( my $path = $self->path ) {
        for my $lib (@INC) {
            next if ref $lib;

            # remove last "/" from lib path
            $lib =~ s[[/\\]+\z][]sm;

            if ( $path =~ m[\A\Q$lib\E/(.+)\z]sm ) {
                my $res;

                $res->{lib} = $lib;

                $res->{name} = $1;

                return $res;
            }
        }
    }

    return;
}

sub _build_name ($self) {
    if ( my $res = $self->_split_path ) {
        $self->{lib} = $res->{lib};

        return $res->{name};
    }

    return;
}

sub _build_path ($self) {
    return $self->lib . '/' . $self->name if $self->lib && $self->name;

    return;
}

sub _build_lib ($self) {
    if ( my $res = $self->_split_path ) {
        $self->{name} = $res->{name};

        return $res->{lib};
    }

    return;
}

sub _build_content ($self) {
    return P->file->read_bin( $self->path ) if $self->path;

    return;
}

sub _build_is_cpan_module ($self) {
    return 0 if !$self->lib;

    return $self->lib_is_dist( $self->lib ) ? 0 : 1;
}

sub _build_is_crypted ($self) {
    return 0 if !$self->content;

    return 1 if $self->content->$* =~ /^use\s+Filter::Crypto::Decrypt;/sm;

    return 0;
}

sub _build_abstract ($self) {
    return if !$self->content;

    return if $self->is_crypted;

    if ( $self->content->$* =~ /=head1\s+NAME\s*[[:alpha:]][[:alnum:]]*(?:::[[:alnum:]]+)*\s*-\s*([^\n]+)/smi ) {
        return $1;
    }

    return;
}

sub _build_version ($self) {
    return if !$self->content;

    return if $self->is_crypted;

    if ( $self->content->$* =~ m[^\s*package\s+\w[\w\:\']*\s+(v?[\d._]+)\s*;]sm ) {
        return version->new($1);
    }

    return;
}

sub _build_auto_deps ($self) {
    return unless my $name = $self->name;

    $name = P->path($name);

    return if $name->{suffix} eq 'pl';

    my $auto_path = P->path("auto/$name->{dirname}/$name->{filename_base}")->{path};

    my $so_filename = "$name->{filename_base}.$Config{dlext}";

    my $deps;

    for my $lib ( map { P->path($_) } "$ENV->{INLINE_DIR}/lib", @INC ) {
        if ( -f "$lib/$auto_path/$so_filename" ) {
            $deps->{"$auto_path/$so_filename"} = "$lib/$auto_path/$so_filename";

            # add .ix, .al
            for my $file ( ( P->path("$lib/$auto_path")->read_dir( abs => 0, is_dir => 0, max_depth => 0 ) // [] )->@* ) {
                if ( defined $file->{suffix} && ( $file->{suffix} eq 'ix' || $file->{suffix} eq 'al' ) ) {
                    $deps->{"$auto_path/$file"} = "$lib/$auto_path/$file";
                }
            }

            last;
        }
    }

    return $deps;
}

sub clear ($self) {
    delete $self->{content};

    delete $self->{is_crypted};

    delete $self->{version};

    delete $self->{abstract};

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 149                  | RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller qr// chunks                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Perl::Module - provides static info about perl module

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
