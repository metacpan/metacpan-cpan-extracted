# NAME

Pcore::WebDriver - non-blocking WebDriver protocol implementation

# SYNOPSIS

    use Pcore::WebDriver;

    my $cv = AE::cv;

    my $wd1 = Pcore::WebDriver->new_phantomjs;
    my $wd2 = Pcore::WebDriver->new_chrome;

    # manage several browsers simultaneously from the single process
    $wd1->get('https://www.google.com/', sub ($res) {
        die $res if !$res;

        $wd1->find_element_by_xpath(..., sub ($web_element) {
            return;
        });

        return;
    });

    # this is a non-blocking call
    $wd2->get('https://www.facebook.com/', sub ($res) {
        die $res if !$res;

        # also non-blocking
        $wd1->find_element_by_xpath(..., sub ($web_element) {
            return;
        });

        return;
    });

    # calls without defined callback, or called with defined return context (defined wantarray) - are blocking
    # blocking call:
    my $res = $wd1->find_element_by_id('id');

    # also blocking:
    $wd1->find_element_by_id('id');

    $cv->recv;

# DESCRIPTION

# ATTRIBUTES

# METHODS

# SEE ALSO

# AUTHOR

zdm <zdm@softvisio.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.
