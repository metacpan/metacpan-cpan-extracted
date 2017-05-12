use Test::More tests => 2;
use Pod::Strip;


{
    my $code=<<'EOCODE';
#!/usr/bin/perl


=pod

the great hello world script

including lots of POD

=cut

# print it
print "Hello, world!\n";

exit "done";

=pod

more pod

=cut

EOCODE
    my $podless;
    my $p=Pod::Strip->new;
    $p->replace_with_comments(1);

    is($p->replace_with_comments(),1);


    $p->output_string(\$podless);
    $p->parse_string_document($code);

    is ($podless,
'#!/usr/bin/perl


# stripped POD
# stripped POD
# stripped POD
# stripped POD
# stripped POD
# stripped POD
# stripped POD

# print it
print "Hello, world!\n";

exit "done";

# stripped POD
# stripped POD
# stripped POD
# stripped POD
# stripped POD

','pod stripped');
}

