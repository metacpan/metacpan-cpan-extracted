use Text::Autoformat 'autoformat';
use Perl6::Placeholders;

$DB::single=1;
my $str = "a cat on a mat" x 100;
*autoformat_with = { autoformat($str, $^config) };

	
print "option 1:\n", autoformat_with({right=>50});
print "option 2:\n", autoformat_with({right=>60});
print "option 3:\n", autoformat_with({left=>1,justify=>'full'});

__END__

	
