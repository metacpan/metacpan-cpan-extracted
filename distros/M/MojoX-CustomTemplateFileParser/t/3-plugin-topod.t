use strict;
use Test::More;
use MojoX::CustomTemplateFileParser;

my $parser = MojoX::CustomTemplateFileParser->new(path => 'corpus/test-1.mojo', output => ['Pod']);

my $expected = q{

=begin html

<p>
Text before the test
</p>

=end html

    %= link_to 'MetaCPAN', 'http://www.metacpan.org/'

=begin html

<p>
Text between template and expected
</p>

=end html

    <a href="http://www.metacpan.org/">MetaCPAN</a>

=begin html

<p>
Text after expected.

</p>

=end html

};

is $parser->to_pod(1), $expected, 'Creates correct pod';


done_testing;
