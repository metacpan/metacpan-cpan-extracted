package MozRepl::Plugin::JSON;

use strict;
use warnings;

use base qw(MozRepl::Plugin::Base);

use Carp::Clan qw(croak);

=head1 NAME

MozRepl::Plugin::JSON - To JSON string plugin.

=head1 VERSION

version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSYS

    use MozRepl;
    use MozRepl::Util;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/JSON/] } });
    print $repl->json({ source => MozRepl::Util->javascript_value({foo => 1, bar => 2}) });

=head1 DESCRIPTION

Add json() method to L<MozRepl>.

=head1 METHODS

=head2 setup($ctx, $args)

Load script at http://www.thomasfrank.se/downloadableJS/jsonStringify.js

=cut

sub setup {
    my ($self, $ctx, $args) = @_;

    $ctx->execute($self->process('setup', { repl => $ctx->repl }));
}

=head2 execute($ctx, $args)

=over 4

=item $ctx

Context object. See L<MozRepl>.

=item $args

Hash reference.

=over 4

=item source

Source string. If you want to JavaScript literal, then use MozRepl::Util->javascript_value() method.
See L<MozRepl::Util/javascript_value($value)>.

=back

=back

=cut

sub execute {
    my ($self, $ctx, $args) = @_;

    my $cmd = $self->process('execute', { repl => $ctx->repl, source => $args->{source} });
    my @result = $ctx->execute($cmd);

    if ($result[$#result - 1] =~ /\!{3} InternalError: /) { ### recursive error
        $ctx->log->debug($result[$#result - 1]);

        croak($result[$#result - 1]);
    }

    return join("", @result);
}

=head1 SEE ALSO

=over 4

=item L<MozRepl::Plugin::Base>

=item L<MozRepl::Util>

=item L<Data::JavaScript::Anon>

=item L<JavaScript::Minifier>

=item http://www.thomasfrank.se/downloadableJS/jsonStringify.js

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-json@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::JSON

__DATA__
__execute__
JSONstring.make([% source %]);
__setup__
JSONstring={compactOutput:false,includeProtos:false,includeFunctions:false,detectCirculars:true,restoreCirculars:true,make:function(arg,restore){this.restore=restore;this.mem=[];this.pathMem=[];return this.toJsonStringArray(arg).join('');},toObject:function(x){eval("this.myObj="+x);if(!this.restoreCirculars||!alert){return this.myObj};this.restoreCode=[];this.make(this.myObj,true);var r=this.restoreCode.join(";")+";";eval('r=r.replace(/\\W([0-9]{1,})(\\W)/g,"[$1]$2").replace(/\\.\\;/g,";")');eval(r);return this.myObj},toJsonStringArray:function(arg,out){if(!out){this.path=[]};out=out||[];var u;switch(typeof arg){case'object':this.lastObj=arg;if(this.detectCirculars){var m=this.mem;var n=this.pathMem;for(var i=0;i<m.length;i++){if(arg===m[i]){out.push('"JSONcircRef:'+n[i]+'"');return out}};m.push(arg);n.push(this.path.join("."));};if(arg){if(arg.constructor==Array){out.push('[');for(var i=0;i<arg.length;++i){this.path.push(i);if(i>0)
out.push(',\n');this.toJsonStringArray(arg[i],out);this.path.pop();}
out.push(']');return out;}else if(typeof arg.toString!='undefined'){out.push('{');var first=true;for(var i in arg){if(!this.includeProtos&&arg[i]===arg.constructor.prototype[i]){continue};this.path.push(i);var curr=out.length;if(!first)
out.push(this.compactOutput?',':',\n');this.toJsonStringArray(i,out);out.push(':');this.toJsonStringArray(arg[i],out);if(out[out.length-1]==u)
out.splice(curr,out.length-curr);else
first=false;this.path.pop();}
out.push('}');return out;}
return out;}
out.push('null');return out;case'unknown':case'undefined':case'function':out.push(this.includeFunctions?arg:u);return out;case'string':if(this.restore&&arg.indexOf("JSONcircRef:")==0){this.restoreCode.push('this.myObj.'+this.path.join(".")+"="+arg.split("JSONcircRef:").join("this.myObj."));};out.push('"');var a=['\n','\\n','\r','\\r','"','\\"'];arg+="";for(var i=0;i<6;i+=2){arg=arg.split(a[i]).join(a[i+1])};out.push(arg);out.push('"');return out;default:out.push(String(arg));return out;}}}
__END__
