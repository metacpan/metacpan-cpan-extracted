package Prophet::Devel;
{
  $Prophet::Devel::VERSION = '0.001';
}

# ABSTRACT: Installs the modules and tools needed for hacking on Prophet


1;

__END__

=pod

=head1 NAME

Prophet::Devel - Installs the modules and tools needed for hacking on Prophet

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  ~/Prophet$ prophet-devel-setup
  ...
  ~/Prophet$

=head1 DESCRIPTION

Just run the C<prophet-devel-setup> script from the root of your Prophet checkout.
It will use your CPAN client to install all the requirements for hacking on
Prophet (Dist::Zilla, Code::TidyAll) and a git pre-commit hook to check your
commits for any policy violations.

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Ioan Rogers.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
