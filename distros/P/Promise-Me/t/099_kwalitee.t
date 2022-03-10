# -*- perl -*-
BEGIN 
{
    use Test2::V0;
	unless( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} )
	{
		skip_all( 'These tests are for author or release candidate testing');
	}
}

eval { require Test::Kwalitee; Test::Kwalitee->import() }; 
skip_all( 'Test::Kwalitee not installed; skipping' ) if $@;

done_testing();

__END__

