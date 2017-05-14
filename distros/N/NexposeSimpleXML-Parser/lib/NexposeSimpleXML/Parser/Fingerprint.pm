# $sslversion: Cipher.pm 18 2008-05-05 23:55:18Z jabra $
package NexposeSimpleXML::Parser::Fingerprint;
{
    use Object::InsideOut;

    my @certainty : Field : Arg(certainty) : Get(certainty);
    my @description : Field : Arg(description) : Get(description);
    my @vendor : Field : Arg(vendor) : Get(vendor);
    my @family : Field : Arg(family) : Get(family);
    my @product : Field : Arg(product) : Get(product);
    my @version : Field : Arg(version) : Get(version);
    my @device_class : Field : Arg(device_class) : Get(device_class);
    my @arch : Field : Arg(arch) : Get(arch);
}
1;
