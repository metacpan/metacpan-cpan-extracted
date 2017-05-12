package main;
use Text;

my $text = new Text;
$text->setText('some text');
print $text->getText();     # Returns 'some text';
