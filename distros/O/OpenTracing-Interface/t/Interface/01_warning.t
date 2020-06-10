use Test::Most;

warning_like {
    require OpenTracing::Interface
    #
    # use would not be of any use,
    # the warning is produced at compile time, before runing this test itself.
    
} qr/^Do not 'use' "OpenTracing::Interface" !!!/,
"Told you ... Don't use this";

done_testing();

1;
