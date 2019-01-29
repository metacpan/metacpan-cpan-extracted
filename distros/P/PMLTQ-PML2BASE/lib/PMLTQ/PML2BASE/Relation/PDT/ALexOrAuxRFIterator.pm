package PMLTQ::PML2BASE::Relation::PDT::ALexOrAuxRFIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::PML2BASE::Relation::PDT::ALexOrAuxRFIterator::VERSION = '3.0.1';
# ABSTRACT: a/lex.rf or a/aux.rf relation iterator for PDT like treebanks

use strict;
use warnings;


sub init_sql {
  my ($table_name, $schema, $desc, $fh) = @_;

  $fh->{'#POST_SQL'}->print(<<"EOF");
INSERT INTO "${table_name}"
  SELECT t."#idx" AS "#idx", a."lex" AS "#value"
    FROM "t-node" t JOIN "t-a" a ON a."#idx"=t."a"
  UNION
  SELECT t."#idx" AS "#idx", aux."#value" AS "#value"
    FROM "t-node" t JOIN "t-a" a ON a."#idx"=t."a" JOIN "t-a/aux.rf" aux ON aux."#idx"=a."aux.rf"
  UNION
  SELECT r."#idx" AS "#idx", r."atree" FROM "t-root" r;
EOF
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::PML2BASE::Relation::PDT::ALexOrAuxRFIterator - a/lex.rf or a/aux.rf relation iterator for PDT like treebanks

=head1 VERSION

version 3.0.1

=head1 AUTHORS

=over 4

=item *

Petr Pajas <pajas@ufal.mff.cuni.cz>

=item *

Jan Štěpánek <stepanek@ufal.mff.cuni.cz>

=item *

Michal Sedlák <sedlak@ufal.mff.cuni.cz>

=item *

Matyáš Kopp <matyas.kopp@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Institute of Formal and Applied Linguistics (http://ufal.mff.cuni.cz).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
