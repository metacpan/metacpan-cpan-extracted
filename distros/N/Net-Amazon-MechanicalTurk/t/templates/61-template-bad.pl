
print <<END_XML;
<data>
    <title>$params{title}</title>
    <subTitle>$params{subTitle}</title>
    <author>$params{author}</title>
    <genre>$params{genre}</genre>
    <kids>
END_XML

foreach my $kid (@{$params{family}{kid}}) {
    printf "        <kid name='%s'/>\n", $kid;
}

# I have a syntax error
))))

print <<END_XML;
    </kids>
</data>
END_XML

