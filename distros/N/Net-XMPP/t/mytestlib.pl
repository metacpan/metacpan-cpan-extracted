
sub testDefined
{
    my ($obj, $tag, $name) = @_;
    my $ltag = lc($tag);
	$name = "" unless defined $name;

    my $defined;
    eval "\$defined = \$obj->Defined$tag();";
    die($@) if ($@);
    is( $defined, 1, "$name: $ltag defined" );
}

sub testNotDefined
{
    my ($obj, $tag, $name) = @_;
    my $ltag = lc($tag);
	$name = "" unless defined $name;

    my $defined;
    eval "\$defined = \$obj->Defined$tag();";
    die($@) if ($@);
    is( $defined, '', "$name: $ltag not defined" );
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

    testNotDefined($obj, $tag, "Scalar");
    testSetScalar(@_);
}

sub testSetScalar
{
    my ($obj, $tag, $value) = @_;
    my $ltag = lc($tag);

    eval "\$obj->Set$tag(\$value);";
    die($@) if ($@);
    testPostScalar(@_);
}

sub testRemove
{
    my ($obj, $tag) = @_;
    my $ltag = lc($tag);

    testDefined($obj, $tag, "Remove");
    eval "\$obj->Remove$tag();";
    die($@) if ($@);
    testNotDefined($obj, $tag, "Remove");
}

sub testPostScalar
{
    my ($obj, $tag, $value) = @_;
    my $ltag = lc($tag);

    testDefined($obj, $tag, "PostScalar");

    my $get;
    eval "\$get = \$obj->Get$tag();";
    die($@) if ($@);
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

    testNotDefined($obj,$tag,"Flag");

    my $get;
    eval "\$get = \$obj->Get$tag();";
    die($@) if ($@);
    is( $get, '', "$ltag  is not set" );
    testSetFlag(@_);
}

sub testSetFlag
{
    my ($obj, $tag) = @_;
    my $ltag = lc($tag);

    eval "\$obj->Set$tag();";
    die($@) if ($@);
    testPostFlag(@_);
}

sub testPostFlag
{
    my ($obj, $tag) = @_;
    my $ltag = lc($tag);

    testDefined($obj, $tag, "PostFlag");

    my $get;
    eval "\$get = \$obj->Get$tag();";
    die($@) if ($@);
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

    testNotDefined($obj, $tag, "JID");
    testSetJID(@_);
}

sub testSetJID
{
    my ($obj, $tag, $user, $server, $resource) = @_;
    my $ltag = lc($tag);

    my $value = $user.'@'.$server.'/'.$resource;

    eval "\$obj->Set$tag(\$value);";
    die($@) if ($@);
    testPostJID(@_);
}

sub testPostJID
{
    my ($obj, $tag, $user, $server, $resource) = @_;
    my $ltag = lc($tag);

    my $value = $user.'@'.$server.'/'.$resource;

    testDefined($obj, $tag,"PostJID");

    my $get;
    eval "\$get = \$obj->Get$tag();";
    die($@) if ($@);
    is( $get, $value, "$ltag  eq '$value'" );

    my $jid;
    eval "\$jid = \$obj->Get$tag(\"jid\");";
    die($@) if ($@);
    ok( defined($jid), "jid object defined");
    isa_ok( $jid, 'Net::XMPP::JID');
    is( $jid->GetUserID(), $user , "user eq '$user'");
    is( $jid->GetServer(), $server , "server eq '$server'");
    is( $jid->GetResource(), $resource , "resource eq '$resource'");
}

sub testFieldJID
{
    my ($hash, $tag, $user, $server, $resource) = @_;
    my $ltag = lc($tag);

    testDefined( $obj, $tag, "FieldJID");

    my $jid = $hash->{$ltag};
    isa_ok( $jid, 'Net::XMPP::JID');
    is( $jid->GetUserID(), $user , "user eq '$user'");
    is( $jid->GetServer(), $server , "server eq '$server'");
    is( $jid->GetResource(), $resource , "resource eq '$resource'");
}

1;
