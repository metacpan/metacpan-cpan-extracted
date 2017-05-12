use strict;
use warnings;
package Task::CPAN::Reporter;
# ABSTRACT: Install CPAN::Reporter and related dependencies

our $VERSION = '0.003';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::CPAN::Reporter - Install CPAN::Reporter and related dependencies

=head1 VERSION

version 0.003

=head1 DESCRIPTION

In order to support CPAN Testers who desire a very minimal test
setup, CPAN::Reporter does not include several dependencies that
a casual CPAN Tester requires.  This Task distribution is provided
to help users install common dependencies together.

=head1 TASK CONTENTS

=head2 Modules Included

=head3 L<CPAN::Reporter> 1.1902

=head3 L<Test::Reporter::Transport::Metabase> 1.999008

=head3 L<IO::Socket::SSL> 1.42

=head3 L<Net::SSLeay> 1.49

=head3 L<Mozilla::CA>

=head3 L<CPAN::Meta::YAML> 0.016

=head1 USAGE

This module has no direct functionality.  It is merely a placeholder
for prerequisites.  Installing it will ensure all the prerequisites listed
above are satisfied.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
