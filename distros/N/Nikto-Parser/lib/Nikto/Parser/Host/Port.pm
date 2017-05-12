# $Id: Port.pm 142 2009-10-16 19:13:45Z jabra $
package Nikto::Parser::Host::Port;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;

    my @port : Field : Arg(port) : Get(port);
    my @banner : Field : Arg(banner) : Get(banner);
    my @start_scan_time : Field : Arg(start_scan_time) : Get(start_scan_time);
    my @end_scan_time : Field : Arg(end_scan_time) : Get(end_scan_time);
    my @elasped_scan_time : Field : Arg(elasped_scan_time) :
        Get(elasped_scan_time);
    my @siteip : Field : Arg(siteip) : Get(siteip);
    my @sitename : Field : Arg(sitename) : Get(sitename);
    my @items : Field : Arg(items) : Get(items) :
        Type(List(Nikto::Parser::Host::Port::Item));
    my @items_tested : Field : Arg(items_tested) : Get(items_tested);
    my @items_found : Field : Arg(items_found) : Get(items_found);

    sub get_all_items {
        my ($self) = @_;
        my @items = @{ $self->items };
        return @items;
    }
}
1;
