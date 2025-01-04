package MooseX::Getopt::ProcessedArgv;
# ABSTRACT: MooseX::Getopt::ProcessedArgv - Class containing the results of process_argv

our $VERSION = '0.78';

use Moose;
use namespace::autoclean;

has 'argv_copy'          => (is => 'ro', isa => 'ArrayRef');
has 'extra_argv'         => (is => 'ro', isa => 'ArrayRef');
has 'usage'              => (is => 'ro', isa => 'Maybe[Object]');
has 'constructor_params' => (is => 'ro', isa => 'HashRef');
has 'cli_params'         => (is => 'ro', isa => 'HashRef');

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Getopt::ProcessedArgv - MooseX::Getopt::ProcessedArgv - Class containing the results of process_argv

=head1 VERSION

version 0.78

=head1 SYNOPSIS

  use My::App;

  my $pa = My::App->process_argv(@params);
  my $argv_copy          = $pa->argv_copy();
  my $extra_argv         = $pa->extra_argv();
  my $usage              = $pa->usage();
  my $constructor_params = $pa->constructor_params();
  my $cli_params         = $pa->cli_params();

=head1 DESCRIPTION

This object contains the result of a L<MooseX::Getopt/process_argv> call. It
contains all the information that L<MooseX::Getopt/new_with_options> uses
when calling new.

=head1 METHODS

=head2 argv_copy

Reference to a copy of the original C<@ARGV> array as it originally existed
at the time of C<new_with_options>.

=head2 extra_arg

Arrayref of leftover C<@ARGV> elements that L<Getopt::Long> did not parse.

=head2 usage

Contains the L<Getopt::Long::Descriptive::Usage> object (if
L<Getopt::Long::Descriptive> is used).

=head2 constructor_params

Parameters passed to process_argv.

=head2 cli_param

Command-line parameters parsed out of C<@ARGV>.

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
