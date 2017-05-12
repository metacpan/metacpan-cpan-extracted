Pod::POM - POD Object Model
---------------------------

This module implements a parser to convert Pod documents into a simple object
model form known hereafter as the Pod Object Model (POM). The object model is
generated as a hierarchical tree of nodes, each of which represents a
different element of the original document.  The tree can be walked manually
and the nodes examined, printed or otherwise manipulated.  In addition,
Pod::POM supports and provides view objects which can automatically traverse
the tree, or section thereof, and generate an output representation in one
form or another.  The Template Toolkit Pod plugin interfaces to this module.

See the [Pod::POM documentation](https://metacpan.org/pod/Pod::POM) for further details.


Support
-------

The Pod::POM mailing list provides a forum for discussing these modules.

To subscribe to the mailing list, send an email to:

    pod-pom-request@template-toolkit.org

with the message 'subscribe' in the body.  You can also use the web interface to subscribe or browse the archives:

    http://mail.template-toolkit.org/mailman/listinfo/pod-pom



Author
------

Pod::POM was originally written by Andy Wardley <abw@wardley.org>.

Andrew Ford <A.Ford@ford-mason.co.uk> is co-maintainer as of March 2009.


COPYRIGHT
---------

Copyright (C) 2000-2002 Andy Wardley.  All Rights Reserved.
Copyright (C) 2009-2015 Andrew Ford.   All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

