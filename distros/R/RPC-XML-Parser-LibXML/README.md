# NAME

RPC::XML::Parser::LibXML - Fast XML-RPC parser with libxml

# SYNOPSIS

    use RPC::XML::Parser::LibXML;

    my $req = parse_rpc_xml(qq{
      <methodCall>
        <methodName>foo.bar</methodName>
        <params>
          <param><value><string>Hello, world!</string></value></param>
        </params>
      </methodCall>
    });
    # $req is a RPC::XML::request

# DESCRIPTION

RPC::XML::Parser::LibXML is fast XML-RPC parser written with XML::LibXML.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF GMAIL COM>

Tatsuhiko Miyagawa <miyagawa@cpan.org>

# SEE ALSO

[RPC::XML::Parser](http://search.cpan.org/perldoc?RPC::XML::Parser), [RPC::XML::Parser::XS](http://search.cpan.org/perldoc?RPC::XML::Parser::XS), [XML::LibXML](http://search.cpan.org/perldoc?XML::LibXML)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
