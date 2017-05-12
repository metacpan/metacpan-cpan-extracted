use Test::Dependencies
	exclude => [qw/Test::Dependencies Test::Base Test::Perl::Critic Shell::Amazon::S3/],
	style   => 'light';
ok_dependencies();
