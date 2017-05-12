package MooseX::App::Cmd::Command;

our $VERSION = '0.32';

use Moose;
use Getopt::Long::Descriptive ();
use namespace::autoclean;
extends 'Moose::Object', 'App::Cmd::Command';
with 'MooseX::Getopt';

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
    isa       => 'MooseX::App::Cmd',
);

override _process_args => sub {
    my ($class, $args) = @_;
    local @ARGV = @{$args};

    my $config_from_file;
    if ($class->meta->does_role('MooseX::ConfigFromFile')) {
        local @ARGV = @ARGV;

        my $configfile;
        my $opt_parser;
        {
            ## no critic (Modules::RequireExplicitInclusion)
            $opt_parser
                = Getopt::Long::Parser->new( config => ['pass_through'] );
        }
        $opt_parser->getoptions( 'configfile=s' => \$configfile );
        if (not defined $configfile
            and $class->can('_get_default_configfile'))
        {
            $configfile = $class->_get_default_configfile();
        }

        if (defined $configfile) {
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

        # params from CLI are also fields in MooseX::Getopt
        $config_from_file
            ? (%$config_from_file, %{ $processed{params} })
            : %{ $processed{params} },
    );
};

sub _usage_format {    ## no critic (ProhibitUnusedPrivateSubroutines)
    return shift->usage_desc;
}

## no critic (Modules::RequireExplicitInclusion)
__PACKAGE__->meta->make_immutable();
1;

# ABSTRACT: Base class for MooseX::Getopt based App::Cmd::Commands

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::App::Cmd::Command - Base class for MooseX::Getopt based App::Cmd::Commands

=head1 VERSION

version 0.32

=head1 SYNOPSIS

    use Moose;

    extends qw(MooseX::App::Cmd::Command);

    # no need to set opt_spec
    # see MooseX::Getopt for documentation on how to specify options
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
L<MooseX::Getopt|MooseX::Getopt> and the glue to combine the two.

=head1 METHODS

=head2 _process_args

Replaces L<App::Cmd::Command|App::Cmd::Command>'s argument processing in favor
of L<MooseX::Getopt|MooseX::Getopt> based processing.

If your class does the L<MooseX::ConfigFromFile|MooseX::ConfigFromFile> role
(or any of its consuming roles like
L<MooseX::SimpleConfig|MooseX::SimpleConfig>), this will provide an additional
C<--configfile> command line option for loading options from a configuration
file.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-App-Cmd>
(or L<bug-MooseX-App-Cmd@rt.cpan.org|mailto:bug-MooseX-App-Cmd@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
http://lists.perl.org/list/moose.html.

There is also an irc channel available for users of this distribution, at
irc://irc.perl.org/#moose.

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
