use Test::More;

BEGIN {
    use_ok('NLP::Service');
}
can_ok( 'NLP::Service', 'run' );
can_ok( 'NLP::Service', 'load_models' );
done_testing();
__END__
COPYRIGHT: 2011. Vikas Naresh Kumar.
AUTHOR: Vikas Naresh Kumar
DATE: 24th May 2011
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
