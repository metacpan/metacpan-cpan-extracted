#! perl
use strict;
use warnings;
use Zydeco::Lite;
use Types::Standard -types;
use Types::Path::Tiny -types;

app 'MyApp' => sub {
	class 'Person' => sub {
		has 'name' => (
			type    => Str,
			default => \"What's the person's name?",
		);
		has 'images' => (
			type    => ArrayRef[File],
			default => \"Select images of the person",
		);
	};
};

my $bob = MyApp->new_person;
print "His name is: ", $bob->name, "\n";
