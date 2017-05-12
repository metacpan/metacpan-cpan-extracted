use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

use Class::Load;
use DateTime;
use Template;

{ package DateTime::Format::Foo;
  sub new { return 'DateTime::Format::Foo' } # heh
  sub format_datetime { my ($self, $date) = @_; 'the foo formatter' }
}

sub render($) {
    my $template = shift;
    my $engine = Template->new;
    my $out;
    $engine->process(
        \$template,
        {
            date => DateTime->new(
                month  => 5,
                day    => 19,
                year   => 1985,
                hour   => 0,
                minute => 0,
                second => 0
            ),
        },
        \$out)
      or die "Failed to render: ". $engine->error;
    return $out;
}

throws_ok { render '[% USE foo = DateTime::Format() %]' }
  qr/need class name/, 'cannot create formatter without class';

throws_ok { render '[% USE foo = DateTime::Format("This::Is::Not::A::Class") %]' }
  qr/Can't locate/, 'cannot create formatter with bogus class name';

is render '[% USE foo = DateTime::Format("DateTime::Format::Foo") %][% foo.format(date) %]', 'the foo formatter';

SKIP: {
    skip "need DateTime::Format::Strptime", 1
      unless eval { Class::Load::load_class('DateTime::Format::Strptime') };
   is render q|[% USE f = DateTime::Format('DateTime::Format::Strptime', |.
             q|{ pattern => '%Y' }) %][% f.format(date) %]|,
    '1985', 'Strptime example works';
}
