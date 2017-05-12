use 5.010;
use warnings;
BEGIN{
    use Test::More;
    plan skip_all => "Moose required for testing moosey objrules" if !eval{require Moose};
}

use Test::More 'no_plan';

# Use this class declaration to check that classes with ctors
# actually call the ctor when objrules use them...

use Moose::Util::TypeConstraints;
    subtype 'Non::Regex::Int',
         as 'Num',
         where { int($_) == $_ };
no Moose::Util::TypeConstraints;

{ package Speaker;

    use Moose;

    has 'name'  => (is => 'rw', isa => 'Str');
    has 'alias' => (is => 'rw', isa => 'Str');
    has 'id'    => (is => 'rw', isa => 'Non::Regex::Int');
}

my $parser = do{
    use Regexp::Grammars;
    qr{
        <speaker>

        <objrule: Speaker=speaker>
            \<a href=\"/yn2011/user/<id>\"\>
            <name>
            (?:\(\&lrm;<alias>\&lrm;\))

        <token: name>
            \w+ (?:(?:<.ws>|\-|\') \w+)

        <token: alias>
            \w+

        <token: id>
            \d+
    }xms
};

my $target = {
      "" => "<a href=\"/yn2011/user/1613\">Nathan Gray (&lrm;kolibrie&lrm;)",
      "speaker" => bless({
        "" => "<a href=\"/yn2011/user/1613\">Nathan Gray (&lrm;kolibrie&lrm;)",
        "alias" => "kolibrie",
        "id" => 1613,
        "name" => "Nathan Gray",
      }, "Speaker"),
};

my $input = do{ local $/; <DATA>};
chomp $input;
my $original_input = $input;

ok +($input =~ $parser)    => 'Matched';
is_deeply \%/, $target     => 'Returned correct data structure';


__DATA__
<a href="/yn2011/user/1613">Nathan Gray (&lrm;kolibrie&lrm;)</a> - <a href="/yn2011/talk/3356"><b>&lrm;Practical Extraction with Regexp::Grammars&lrm;</b></a> (50&nbsp;min)  <span id="starcount-3356" style="white-space:nowrap"><span class="starcount">9</span><img style="vertical-align:middle" src="/images/picked.gif" /></span>
