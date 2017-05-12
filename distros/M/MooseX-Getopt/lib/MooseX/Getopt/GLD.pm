package MooseX::Getopt::GLD;
# ABSTRACT: A Moose role for processing command line options with Getopt::Long::Descriptive

our $VERSION = '0.71';

use strict;
use warnings;
use MooseX::Role::Parameterized 1.01;
use Getopt::Long::Descriptive 0.088;
with 'MooseX::Getopt::Basic';
use namespace::autoclean;

parameter getopt_conf => (
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

role {

    my $p = shift;
    my $getopt_conf = $p->getopt_conf;

    has usage => (
        is => 'rw', isa => 'Getopt::Long::Descriptive::Usage',
        traits => ['NoGetopt'],
    );

    # captures the options: --help --usage --? -? -h
    has help_flag => (
        is => 'ro', isa => 'Bool',
        traits => ['Getopt'],
        cmd_flag => 'help',
        cmd_aliases => [ qw(usage ? h) ],
        documentation => 'Prints this usage information.',
    );

    around _getopt_spec => sub {
        shift;
        shift->_gld_spec(@_);
    };

    around _getopt_get_options => sub {
        shift;
        my ($class, $params, $opt_spec) = @_;
        # Check if a special args hash were already passed, or create a new one
        my $args = ref($opt_spec->[-1]) eq 'HASH' ? pop @$opt_spec : {};
        unshift @{$args->{getopt_conf}}, @$getopt_conf;
        push @$opt_spec, $args;
        return Getopt::Long::Descriptive::describe_options($class->_usage_format(%$params), @$opt_spec);
    };

    method _gld_spec => sub {
        my ( $class, %params ) = @_;

        my ( @options, %name_to_init_arg );

        my $constructor_params = $params{params};

        foreach my $opt ( @{ $params{options} } ) {
            push @options, [
                $opt->{opt_string},
                $opt->{doc} || ' ', # FIXME new GLD shouldn't need this hack
                {
                    ( ( $opt->{required} && !exists($constructor_params->{$opt->{init_arg}}) ) ? (required => $opt->{required}) : () ),
                    # NOTE:
                    # remove this 'feature' because it didn't work
                    # all the time, and so is better to not bother
                    # since Moose will handle the defaults just
                    # fine anyway.
                    # - SL
                    #( exists $opt->{default}  ? (default  => $opt->{default})  : () ),
                },
            ];

            my $identifier = lc($opt->{name});
            $identifier =~ s/\W/_/g; # Getopt::Long does this to all option names

            $name_to_init_arg{$identifier} = $opt->{init_arg};
        }

        return ( \@options, \%name_to_init_arg );
    }
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Getopt::GLD - A Moose role for processing command line options with Getopt::Long::Descriptive

=head1 VERSION

version 0.71

=head1 SYNOPSIS

  ## In your class
  package My::App;
  use Moose;

  with 'MooseX::Getopt::GLD';

  # or

  with 'MooseX::Getopt::GLD' => { getopt_conf => [ 'pass_through', ... ] };

  has 'out' => (is => 'rw', isa => 'Str', required => 1);
  has 'in'  => (is => 'rw', isa => 'Str', required => 1);

  # ... rest of the class here

  ## in your script
  #!/usr/bin/perl

  use My::App;

  my $app = My::App->new_with_options();
  # ... rest of the script here

  ## on the command line
  % perl my_app_script.pl -in file.input -out file.dump

=head1 OPTIONS

This role is a parameterized role. It accepts one configuration parameter,
C<getopt_conf>. This parameter is an ArrayRef of strings, which are
L<Getopt::Long> configuration options (see "Configuring Getopt::Long" in
L<Getopt::Long>)

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Getopt>
(or L<bug-MooseX-Getopt@rt.cpan.org|mailto:bug-MooseX-Getopt@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
