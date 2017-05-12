#
# This file is part of Task-XNLSoar-Graphing
#
# This software is copyright (c) 2012 by Nathan Glenn.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Task::XNLSoar::Graphing;
# ABSTRACT: BUNDLE ALL MODULES NECESSARY FOR XNL-SOAR GRAPHING
use strict;
use warnings;
use 5.010;

our $VERSION = '0.03'; # VERSION

1;

__END__

=pod

=head1 NAME

Task::XNLSoar::Graphing - BUNDLE ALL MODULES NECESSARY FOR XNL-SOAR GRAPHING

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    perl -MCPANPLUS -e 'install Task::XNLSoar::Graphing'

=head1 DESCRIPTION

This task is merely a placeholder to pull all modules necessary for XNL-Soar graphing in one go.

=head1 TASK CONTENTS

=head2 Required modules

=head3 L<Soar::WM> 0.03

=head3 L<opts>

=head3 L<Path::Class>

=head2 Install only to retrieve prerequisites

=head3 L<GraphViz>

=head2 Only necessary if you want JSON graphing

=head3 L<JSON::XS>

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nathan Glenn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
