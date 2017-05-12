package Perl::Critic::Lokku;
$Perl::Critic::Lokku::VERSION = '0.002';
use strict;
use warnings;
use utf8;
# ABSTRACT: A collection of Perl::Critic policies from Lokku

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Lokku - A collection of Perl::Critic policies from Lokku

=head1 VERSION

version 0.002

=head1 SYNOPSIS

A collection of policies that we created at Lokku, have a look at each one to
see if you could use any.

=head1 DESCRIPTION

Currently, this distribution only contains policies that check for gotchas
about L<Try::Tiny>.

=head2 TryTiny policies

=head3 L<Perl::Critic::Policy::TryTiny::RequireCatch>

Did you know that C< try { ... } finally { ... }> suppresses all errors? This
policy will require you to include a C<catch> block, even if it's only empty.

=head3 L<Perl::Critic::Policy::TryTiny::ProhibitExitingSubroutine>

Did you know that C<next> inside a C<try> block will exit that block, not the
surrounding loop? This policy will require you use a label at least, and that
you avoid C<return> altogether.

=head1 SEE ALSO

=for :list * L<Perl::Critic>
 * L<Perl::Critic::PolicySummary>

=head1 AUTHOR

David D Lowe <flimm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Lokku <cpan@lokku.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
