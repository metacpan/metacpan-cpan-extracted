use 5.006;

package MouseX::App::Cmd::Command;
use Mouse;

our $VERSION = '0.30'; # VERSION
use Getopt::Long::Descriptive ();
use namespace::autoclean;
extends 'Mouse::Object', 'App::Cmd::Command';
with 'MouseX::Getopt';

has usage => (
    is        => 'ro',
    required  => 1,
    metaclass => 'NoGetopt',
    isa       => 'Object',
);

has app => (
    is        => 'ro',
    required  => 1,
    metaclass => 'NoGetopt',
    isa       => 'MouseX::App::Cmd',
);

override _process_args => sub {
    my ( $class, $args ) = @_;
    local @ARGV = @{$args};

    my $config_from_file;
    if ( $class->meta->does_role('MouseX::ConfigFromFile') ) {
        local @ARGV = @ARGV;

        my $configfile;
        my $opt_parser;
        {
            ## no critic (Modules::RequireExplicitInclusion)
            $opt_parser
                = Getopt::Long::Parser->new( config => ['pass_through'] );
        }
        $opt_parser->getoptions( 'configfile=s' => \$configfile );
        if ( not defined $configfile
            and $class->can('_get_default_configfile') )
        {
            $configfile = $class->_get_default_configfile();
        }

        if ( defined $configfile ) {
            $config_from_file = $class->get_config_from_file($configfile);
        }
    }

    my %processed = $class->_parse_argv(
        params => { argv => \@ARGV },
        options => [ $class->_attrs_to_options($config_from_file) ],
    );

    return (
        $processed{params},
        $processed{argv},
        usage => $processed{usage},

        # params from CLI are also fields in MouseX::Getopt
        $config_from_file
        ? ( %{$config_from_file}, %{ $processed{params} } )
        : %{ $processed{params} },
    );
};

sub _usage_format {    ## no critic (ProhibitUnusedPrivateSubroutines)
    return shift->usage_desc;
}

## no critic (Modules::RequireExplicitInclusion)
__PACKAGE__->meta->make_immutable();
1;

# ABSTRACT: Base class for MouseX::Getopt based App::Cmd::Commands

__END__

=pod

=encoding UTF-8

=for :stopwords יובל קוג'מן (Yuval Kogman) Infinity Interactive, Inc.

=head1 NAME

MouseX::App::Cmd::Command - Base class for MouseX::Getopt based App::Cmd::Commands

=head1 VERSION

version 0.30

=head1 SYNOPSIS

    use Mouse;

    extends qw(MouseX::App::Cmd::Command);

    # no need to set opt_spec
    # see MouseX::Getopt for documentation on how to specify options
    has option_field => (
        isa => 'Str',
        is  => 'rw',
        required => 1,
    );

    sub execute {
        my ( $self, $opts, $args ) = @_;

        print $self->option_field; # also available in $opts->{option_field}
    }

=head1 DESCRIPTION

This is a replacement base class for L<App::Cmd::Command|App::Cmd::Command>
classes that includes
L<MouseX::Getopt|MouseX::Getopt> and the glue to combine the two.

=head1 METHODS

=head2 _process_args

Replaces L<App::Cmd::Command|App::Cmd::Command>'s argument processing in favor
of L<MouseX::Getopt|MouseX::Getopt> based processing.

If your class does the L<MouseX::ConfigFromFile|MouseX::ConfigFromFile> role
(or any of its consuming roles like
L<MouseX::SimpleConfig|MouseX::SimpleConfig>), this will provide an additional
C<--configfile> command line option for loading options from a configuration
file.

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
