
sub testDefined
{
    my ($obj, $tag) = @_;
    my $ltag = lc($tag);

    my $defined;
    eval "\$defined = \$obj->Defined$tag();";
    is( $defined, 1, "$ltag defined" );
}

sub testNotDefined
{
    my ($obj, $tag) = @_;
    my $ltag = lc($tag);

    my $defined;
    eval "\$defined = \$obj->Defined$tag();";
    is( $defined, '', "$ltag not defined" );
}

sub testDefinedField
{
    my ($hash, $tag) = @_;
    my $ltag = lc($tag);

    ok( exists($hash->{$ltag}), "$ltag defined" );
}

sub testScalar
{
    my ($obj, $tag, $value) = @_;
    my $ltag = lc($tag);

    testNotDefined(@_);
    testSetScalar(@_); 
}

sub testSetScalar
{
    my ($obj, $tag, $value) = @_;
    my $ltag = lc($tag);

    eval "\$obj->Set$tag(\$value);";
    testPostScalar(@_);
}

sub testPostScalar
{
    my ($obj, $tag, $value) = @_;
    my $ltag = lc($tag);

    testDefined(@_);

    my $get;
    eval "\$get = \$obj->Get$tag();";
    is( $get, $value, "$ltag eq '$value'" );
}

sub testFieldScalar
{
    my ($hash, $tag, $value) = @_;
    my $ltag = lc($tag);

    testDefinedField(@_);

    is( $hash->{$ltag}, $value , "$ltag eq '$value'");
}

sub testFlag
{
    my ($obj, $tag) = @_;
    my $ltag = lc($tag);

    testNotDefined($obj,$tag,'');

    my $get;
    eval "\$get = \$obj->Get$tag();";
    is( $get, '', "$ltag  is not set" );
    testSetFlag(@_); 
}

sub testSetFlag
{
    my ($obj, $tag) = @_;
    my $ltag = lc($tag);

    eval "\$obj->Set$tag();";
    testPostFlag(@_);
}

sub testPostFlag
{
    my ($obj, $tag) = @_;
    my $ltag = lc($tag);

    testDefined(@_);

    my $get;
    eval "\$get = \$obj->Get$tag();";
    is( $get, 1, "$ltag  is set" );
}

sub testFieldFlag
{
    my ($hash, $tag) = @_;
    my $ltag = lc($tag);

    testDefinedField(@_);

    is( $hash->{$ltag}, 1 , "$ltag is set");
}

sub testJID
{
    my ($obj, $tag, $user, $server, $resource) = @_;
    my $ltag = lc($tag);

    testNotDefined(@_);
    testSetJID(@_);
}

sub testSetJID
{
    my ($obj, $tag, $user, $server, $resource) = @_;
    my $ltag = lc($tag);

    my $value = $user.'@'.$server.'/'.$resource;

    eval "\$obj->Set$tag(\$value);";
    testPostJID(@_);
}

sub testPostJID
{
    my ($obj, $tag, $user, $server, $resource) = @_;
    my $ltag = lc($tag);

    my $value = $user.'@'.$server.'/'.$resource;

    testDefined(@_);

    my $get;
    eval "\$get = \$obj->Get$tag();";
    is( $get, $value, "$ltag  eq '$value'" );

    my $jid;
    eval "\$jid = \$obj->Get$tag(\"jid\");";
    ok( defined($jid), "jid object defined");
    isa_ok( $jid, 'Net::Jabber::JID');
    isa_ok( $jid, 'Net::XMPP::JID');
    is( $jid->GetUserID(), $user , "user eq '$user'");
    is( $jid->GetServer(), $server , "server eq '$server'");
    is( $jid->GetResource(), $resource , "resource eq '$resource'");
}

sub testFieldJID
{
    my ($hash, $tag, $user, $server, $resource) = @_;
    my $ltag = lc($tag);

    testDefined(@_);
    
    my $jid = $hash->{$ltag};
    isa_ok( $jid, 'Net::Jabber::JID');
    isa_ok( $jid, 'Net::XMPP::JID');
    is( $jid->GetUserID(), $user , "user eq '$user'");
    is( $jid->GetServer(), $server , "server eq '$server'");
    is( $jid->GetResource(), $resource , "resource eq '$resource'");
}

1;
