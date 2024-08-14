package Regex::Common::profanity;
use strict;
use warnings;
no warnings 'syntax';

use Regex::Common qw /pattern clean no_defaults/;

our $VERSION = 'v1.0.0'; # VERSION

my $profanity =
'(?:cvff(?:\\ gnxr|\\-gnxr|gnxr|r(?:ef|[feq])|vat|l)?|dhvzf?|fuvg(?:g(?:r(?:ef|[qe])|vat|l)|r(?:ef|[fqel])|vat|[fr])?|g(?:heqf?|jngf?)|jnax(?:r(?:ef|[eq])|vat|f)?|n(?:ef(?:r(?:\\ ubyr|\\-ubyr|ubyr|[fq])|vat|r)|ff(?:\\ ubyrf?|\\-ubyrf?|rq|ubyrf?|vat))|o(?:hyy(?:\\ fuvg(?:g(?:r(?:ef|[qe])|vat)|f)?|\\-fuvg(?:g(?:r(?:ef|[qe])|vat)|f)?|fuvg(?:g(?:r(?:ef|[qe])|vat)|f)?)|ybj(?:\\ wbof?|\\-wbof?|wbof?))|p(?:bpx(?:\\ fhpx(?:ref?|vat)|\\-fhpx(?:ref?|vat)|fhpx(?:ref?|vat))|enc(?:c(?:r(?:ef|[eq])|vat|l)|f)?|h(?:agf?|z(?:vat|zvat|f)))|qvpx(?:\\ urnq|\\-urnq|rq|urnq|vat|yrff|f)|s(?:hpx(?:rq|vat|f)?|neg(?:r[eq]|vat|[fl])?|rygpu(?:r(?:ef|[efq])|vat)?)|un(?:eq[\\-\\ ]?ba|ys(?:\\ n[fe]|\\-n[fe]|n[fe])frq)|z(?:bgure(?:\\ shpx(?:ref?|vat)|\\-shpx(?:ref?|vat)|shpx(?:ref?|vat))|hgu(?:n(?:\\ shpx(?:ref?|vat|[nnn])|\\-shpx(?:ref?|vat|[nnn])|shpx(?:ref?|vat|[nnn]))|re(?:\\ shpx(?:ref?|vat)|\\-shpx(?:ref?|vat)|shpx(?:ref?|vat)))|reqr?))';

my $contextual =
'(?:c(?:bex|e(?:bax|vpxf?)|hff(?:vrf|l)|vff(?:\\ gnxr|\\-gnxr|gnxr|r(?:ef|[feq])|vat|l)?)|dhvzf?|ebbg(?:r(?:ef|[eq])|vat|f)?|f(?:bq(?:q(?:rq|vat)|f)?|chax|perj(?:rq|vat|f)?|u(?:nt(?:t(?:r(?:ef|[qe])|vat)|f)?|vg(?:g(?:r(?:ef|[qe])|vat|l)|r(?:ef|[fqel])|vat|[fr])?))|g(?:heqf?|jngf?|vgf?)|jnax(?:r(?:ef|[eq])|vat|f)?|n(?:ef(?:r(?:\\ ubyr|\\-ubyr|ubyr|[fq])|vat|r)|ff(?:\\ ubyrf?|\\-ubyrf?|rq|ubyrf?|vat))|o(?:ba(?:r(?:ef|[fe])|vat|r)|h(?:ttre|yy(?:\\ fuvg(?:g(?:r(?:ef|[qe])|vat)|f)?|\\-fuvg(?:g(?:r(?:ef|[qe])|vat)|f)?|fuvg(?:g(?:r(?:ef|[qe])|vat)|f)?))|n(?:fgneq|yy(?:r(?:ef|[qe])|vat|f)?)|yb(?:bql|j(?:\\ wbof?|\\-wbof?|wbof?)))|p(?:bpx(?:\\ fhpx(?:ref?|vat)|\\-fhpx(?:ref?|vat)|fhpx(?:ref?|vat)|f)?|enc(?:c(?:r(?:ef|[eq])|vat|l)|f)?|h(?:agf?|z(?:vat|zvat|f)))|q(?:batf?|vpx(?:\\ urnq|\\-urnq|rq|urnq|vat|yrff|f)?)|s(?:hpx(?:rq|vat|f)?|neg(?:r[eq]|vat|[fl])?|rygpu(?:r(?:ef|[efq])|vat)?)|u(?:hzc(?:r(?:ef|[eq])|vat|f)?|n(?:eq[\\-\\ ]?ba|ys(?:\\ n[fe]|\\-n[fe]|n[fe])frq))|z(?:bgure(?:\\ shpx(?:ref?|vat)|\\-shpx(?:ref?|vat)|shpx(?:ref?|vat))|hgu(?:n(?:\\ shpx(?:ref?|vat|[nnn])|\\-shpx(?:ref?|vat|[nnn])|shpx(?:ref?|vat|[nnn]))|re(?:\\ shpx(?:ref?|vat)|\\-shpx(?:ref?|vat)|shpx(?:ref?|vat)))|reqr?))';

tr/A-Za-z/N-ZA-Mn-za-m/ foreach $profanity, $contextual;

pattern
  name   => [qw (profanity)],
  create => '(?:\b(?k:' . $profanity . ')\b)',
  ;

pattern
  name   => [qw (profanity contextual)],
  create => '(?:\b(?k:' . $contextual . ')\b)',
  ;

1;

__END__

=pod

=head1 NAME

Regex::Common::profanity -- provide regexes for profanity

=head1 SYNOPSIS

    use Regex::Common qw /profanity/;

    while (<>) {
        /$RE{profanity}/               and  print "Contains profanity\n";
    }


=head1 DESCRIPTION

Please consult the manual of L<Regex::Common> for a general description
of the works of this interface.

Do not use this module directly, but load it via I<Regex::Common>.

=head2 $RE{profanity}

Returns a pattern matching words -- such as Carlin's "big seven" -- that
are most likely to give offense. Note that correct anatomical terms are
deliberately I<not> included in the list.

Under C<-keep> (see L<Regex::Common>):

=over 4

=item $1

captures the entire word

=back

=head2 C<$RE{profanity}{contextual}>

Returns a pattern matching words that are likely to give offense when
used in specific contexts, but which also have genuinely
non-offensive meanings.

Under C<-keep> (see L<Regex::Common>):

=over 4

=item $1

captures the entire word

=back

=head1 SEE ALSO

L<Regex::Common> for a general description of how to use this interface.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 LICENSE and COPYRIGHT

This software is copyright (c) 2024 of Alceu Rodrigues de Freitas Junior,
glasswalk3r at yahoo.com.br

This file is part of regex-common project.

regex-commonis free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

regex-common is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
regex-common. If not, see (http://www.gnu.org/licenses/).

The original project [Regex::Common](https://metacpan.org/pod/Regex::Common)
is licensed through the MIT License, copyright (c) Damian Conway
(damian@cs.monash.edu.au) and Abigail (regexp-common@abigail.be).

=cut
