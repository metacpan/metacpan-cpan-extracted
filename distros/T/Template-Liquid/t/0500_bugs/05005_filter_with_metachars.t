use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
#
is(Template::Liquid->parse(<<'END')->render(), 'Funny est', 'remove');
{{-'Funny Fun*Fun*est' | remove: 'Fun*' -}}
END
is( Template::Liquid->parse(
                         <<'END')->render(), 'Funny Fun*est', 'remove_first');
{{- 'Funny Fun*Fun*est' | remove_first: 'Fun*', '_' -}}
END
is(Template::Liquid->parse(<<'END')->render(), 'Funny __est', 'replace');
{{- 'Funny Fun*Fun*est' | replace: 'Fun*', '_' -}}
END
is( Template::Liquid->parse(
                       <<'END')->render(), 'Funny _Fun*est', 'replace_first');
{{- 'Funny Fun*Fun*est' | replace_first: 'Fun*', '_' -}}
END
#
done_testing();
