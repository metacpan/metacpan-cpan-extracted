# $Id: Item.pm 136 2009-10-16 18:31:09Z jabra $
package Nikto::Parser::Host::Port::Item;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;

    my @description : Field : Arg(description) : Get(description);
    my @id : Field : Arg(id) : Get(id);
    my @osvdbid : Field : Arg(osvdbid) : Get(osvdbid);
    my @osvdblink : Field : Arg(osvdblink) : Get(osvdblink);
    my @method : Field : Arg(method) : Get(method);
    my @uri : Field : Arg(uri) : Get(uri);
    my @namelink : Field : Arg(namelink) : Get(namelink);
    my @iplink : Field : Arg(iplink) : Get(iplink);
}
1;
