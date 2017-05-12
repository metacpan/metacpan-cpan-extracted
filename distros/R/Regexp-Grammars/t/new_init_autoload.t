use 5.010;
use warnings;
use Test::More 'tests' => 2;

# Use this class declaration to check that classes with ctors
# actually call the ctor when objrules use them...
{ package Speaker;

    sub new {
        my $that = shift;
        #warn "running 'new'\n";
        my $self = bless {}, (ref($that) || $that);
        $self->init(@_);
    }

    sub init {
        my $self = shift;
        #warn "running 'init'\n";
        my %args = (scalar @_ == 1 and UNIVERSAL::isa($_[0], 'HASH')) ? %{ $_[0] } : @_;
        foreach my $accessor (keys %args) {
            $self->$accessor($args{$accessor});
        }
        #warn "returning initialized object\n";
        return $self;
    }

    sub AUTOLOAD {
        my $self = shift;
        our $AUTOLOAD;
        my $var = $AUTOLOAD;
        my $last_colon_pos = rindex($var, ':');
        substr $var, 0, $last_colon_pos+1, q{};
        #warn "running AUTOLOAD as '$var' with param '$_[0]'\n";
        @_ ? ($self->{$var} = shift) : $self->{$var};
    }
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
#is $/{""}, $original_input => 'Captured entire text';


__DATA__
<a href="/yn2011/user/1613">Nathan Gray (&lrm;kolibrie&lrm;)</a> - <a href="/yn2011/talk/3356"><b>&lrm;Practical Extraction with Regexp::Grammars&lrm;</b></a> (50&nbsp;min)  <span id="starcount-3356" style="white-space:nowrap"><span class="starcount">9</span><img style="vertical-align:middle" src="/images/picked.gif" /></span>
