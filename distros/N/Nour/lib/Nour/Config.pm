# vim: ts=4 sw=4 expandtab smarttab smartindent autoindent cindent
package Nour::Config;

use Moose;
use namespace::autoclean;
use YAML qw/LoadFile DumpFile/;
use File::Find;
use List::AllUtils qw/uniq/;

with 'Nour::Base';


has _config => (
    is => 'rw'
    , isa => 'HashRef'
    , required => 1
    , lazy => 1
    , default => sub { {} }
);

has _path => (
    is => 'rw'
    , isa => 'HashRef'
);

has _path_list => (
    is => 'rw'
    , isa => 'ArrayRef'
);

around BUILDARGS => sub {
    my ( $next, $self, @args, $args ) = @_;

    $args = $self->$next( @args );
    $args->{_config} = delete $args->{ '-conf' } if defined $args->{ '-conf' };
    $args->{_path}{ $_ } = delete $args->{ $_ } for grep { $_ ne '_config' } keys %{ $args };
    $args->{_path} ||= {};

    return $args;
};

around BUILD => sub {
    my ( $next, $self, @args ) = @_;

    # Get config directory.
    my %path;
    if ( keys %{ $self->_path } ) {
        for my $name ( keys %{ $self->_path } ) {
            my $path = $self->_path->{ $name };

            if ( $path =~ /^\// and ( -d $path or -f $path and $path =~ /\.ya?ml$/ ) ) {
                $path{ $name } = $path;
            }
            elsif ( -d $self->path( $path ) or -f $self->path( $path ) and $self->path( $path ) =~ /\.ya?ml$/ ) {
                $path{ $name } = $self->path( $path );
            }
            else {
                for my $sub ( qw/config conf cfg/ ) {
                    my $subpath = $self->path( $sub, $path );
                    if ( -d $subpath or -f $subpath and $subpath =~ /\.ya?ml$/ ) {
                        $path{ $name } = $self->path( $sub, $path );
                        last;
                    }
                }
            }
        };
    }
    else {
        check: for my $sub ( qw/config conf cfg/ ) {
            my $path = $self->path( $sub );
            if ( -d $path ) {
                $path{ '-base' } = $path;
                last check;
            }
            else {
                $path{ '-base' } = $path .( -f "$path.yml" ? '.yml' : '.yaml' ) if -f "$path.yml" or -f "$path.yaml";
            }
        }
    }
    return $self->$next( @args ) unless %path;

    my $conf = $self->_config;

    if ( my $path = $path{ '-base' } ) {
        if ( -d $path ) {
            finddepth( sub {
                my $name = $File::Find::name;
                if ( $name =~ qr/\w+\.ya?ml$/ ) {
                    my ( $key, $val );
                    $val = $name;
                    $val =~ s/\/\w+\.ya?ml$//;
                    $key = $val;
                    $key =~ s/^\Q$path\E\/?//;
                    my @key = split /\//, $key;
                    $path{ $key } = $val if $key and not $path{ $key } and $key[ -1 ] ne 'private';
                }
            }, $path );
        }
    }

    $self->_path_list( [ uniq sort values %path ] );

    # Get config files and embedded configuration.
    for my $name ( keys %path ) {
        my @name = split /\//, $name;
        my $path = $path{ $name };
        my $conf = $conf;
        for my $name ( @name ) {
            next if $name eq '-base';
            $conf = $conf->{ $name } ||= {};
        }

        $self->build( conf => $conf, path => $path, name => $name );
    }
    case_exception: {
        if ( $path{ '-base' } and -f $path{ '-base' } ) {
            my $path = $path{ '-base' };
            my $name = shift @{ [ map { my $s = $_; $s =~ s/\.ya?ml$//; $s } ( pop @{ [ split /\//, $path ] } ) ] };
            do {
                my %conf = %{ delete $conf->{ $name } };
                $conf->{ $_ } = $conf{ $_ } for keys %conf;
            } if exists $conf->{ $name } and ref $conf->{ $name } eq 'HASH';
        }
    };

    $self->config( $conf );

    return $self->$next( @args );
};


sub config {
    my $self = shift;
    my @args = @_;

    if ( @args and defined $args[0] ) {
        return $self->_config->{ $args[0] } if scalar @args eq 1 and not ref $args[0];

        my %config = ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;

        for my $key ( keys %config ) {
            $self->_config->{ $key } = $config{ $key };
        }
    }

    return $self->_config;
}

sub build {
    my ( $self, %args ) = @_;
    my ( %file, %conf );

    if ( -f $args{path} and $args{path} =~ /\.ya?ml$/ ) {
        push @{ $file{public} }, $args{path};
        ( my $private = $args{path} ) =~ s/\.ya?ml$/.private/;
        push @{ $file{private} }, $private .( -f "$private.yml" ? '.yml' : '.yaml' ) if -f "$private.yml" or -f "$private.yaml";
    }
    else {
        opendir my $dh, $args{path} or die "Couldn't open directory '$args{path}': $!";
        push @{ $file{public} }, map { "$args{path}/$_" } grep {
            -e "$args{path}/$_" and $_ !~ /^\./ and $_ =~ /\.ya?ml$/
        } readdir $dh;
        closedir $dh;

        # Private sub-dir i.e. "./config/private" for sensitive i.e. .gitignore'd config.
        if ( -d "$args{path}/private" ) {
            my $path = "$args{path}/private";
            opendir my $dh, $path or die "Couldn't open directory '$path': $!";
            push @{ $file{private} }, map { "$path/$_" } grep {
                -e "$path/$_" and $_ !~ /^\./ and $_ =~ /\.ya?ml$/
            } readdir $dh;
            closedir $dh;
        }
    }

    for my $file ( @{ $file{public} } ) {
        my ( $name ) = ( split /\//, $file )[ -1 ] =~ /^(.*)\.ya?ml$/;
        my $conf = LoadFile $file;

        if ( $name eq 'config' or $name eq 'base' ) {
            $conf{public}{ $_ } = $conf->{ $_ } for keys %{ $conf };
        }
        else {
            if ( exists $conf->{ $name } and scalar keys %{ $conf } == 1 ) {
                $conf{public}{ $name } = $conf->{ $name };
            }
            else {
                $conf{public}{ $name }->{ $_ } = $conf->{ $_ } for keys %{ $conf };
            }
        }
    }

    for my $file ( @{ $file{private} } ) {
        my ( $name ) = ( split /\//, $file )[ -1 ] =~ /^(.*)\.ya?ml$/;
        my $conf = LoadFile $file;

        if ( $name eq 'config' or $name eq 'base' ) {
            $conf{private}{ $_ } = $conf->{ $_ } for keys %{ $conf };
        }
        else {
            if ( exists $conf->{ $name } and scalar keys %{ $conf } == 1 ) {
                $conf{private}{ $name } = $conf->{ $name };
            }
            else {
                $conf{private}{ $name }->{ $_ } = $conf->{ $_ } for keys %{ $conf };
            }
        }
    }

    # "Private" config overrides "public."
    $conf{merged} = {};

    $self->merge_hash( $conf{merged}, $conf{public} )  if exists $conf{public};
    $self->merge_hash( $conf{merged}, $conf{private} ) if exists $conf{private};
    $self->merge_hash( $conf{merged}, $args{conf} );
    $self->merge_hash( $args{conf}, $conf{merged} );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Nour::Config

=head1 VERSION

version 0.10

=head1 NAME

Nour::Config

=head1 ABSTRACT

Recursively consumes C<YAML> configuration from the C<config> directory into a hash ref for use in your application.

=head1 USAGE EXAMPLE

=over 2

=item 1. Create a config directory, either C<config>, C<conf>, or C<cfg>.

  you@your_computer:~/code/your_app $ mkdir config
  you@your_computer:~/code/your_app $ mkdir config/application
  you@your_computer:~/code/your_app $ mkdir config/database
  you@your_computer:~/code/your_app $ mkdir config/database/private
  you@your_computer:~/code/your_app $ mkdir -p config/a/deeply/nested/example

=item 2. Create your configuration YAML files

  you@your_computer:~/code/your_app $ echo '---' > config/config.yml
  you@your_computer:~/code/your_app $ echo '---' > config/application/config.yml
  you@your_computer:~/code/your_app $ echo '---' > config/database/config.yml
  you@your_computer:~/code/your_app $ echo '---' > config/database/private/config.yml
  you@your_computer:~/code/your_app $ echo '---' > config/a/deeply/nested/example/neato.yml

=item 3. Edit your configuration YAML with whatever you want.

=item 4. In your script or application, create a Nour::Config instance.

  use Nour::Config;
  use Data::Dumper;
  use feature ':5.10';

then

  # automatically detects and reads from a config, conf, or cfg directory
  my $config = new Nour::Config;

or

  my $config = new Nour::Config (
    -base => 'config/application'
  );

or

  my $config = new Nour::Config (
      -conf => { hash_key => 'override' }
    , -base => 'config'
  );

or

  my $config = new Nour::Config (
    this_becomes_a_hash_key => 'config/database'
  );

finally

    say 'cfg', Dumper $config->config;
    say 'app', Dumper $config->config( 'application' );
    say 'db',  Dumper $config->config->{database};

=back

But it's even better with Moose if you import the config handle, so you can use C<config> as a handle in your script
or application:

    use Moose;
    use Nour::Config;
    use Data::Dumper;

    has _config => (
        is => 'rw'
        , isa => 'Nour::Config'
        , handles => [ qw/config/ ]
        , required => 1
        , lazy => 1
        , default => sub {
            return new Nour::Config ( -base => 'config' );
        }
    );

    sub BUILD {
        my $self = shift;

        print "\nhello world\n", Dumper( $self->config ), "\n";
    }

=head1 METHODS

=head2 config

Returns the configuration accessor, and doubles as a hash ref.

  print "\n", Dumper( $self->config( 'application' ) ), "\n";
  print "\n", Dumper( $self->config->{application} ), "\n";

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
