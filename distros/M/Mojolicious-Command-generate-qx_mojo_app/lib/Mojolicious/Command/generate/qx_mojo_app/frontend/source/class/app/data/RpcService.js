% my $p = shift;
/* ************************************************************************
   Copyright: <%= $p->{year} %> <%= $p->{fullName} %>
   License:   ???
   Authors:   <%= $p->{fullName} %> <<%= $p->{email} %>>
************************************************************************ */
/**
 * initialize us an Rpc object with some extra thrills.
 */
qx.Class.define('<%= $p->{name} %>.data.RpcService', {
    extend : qx.io.remote.Rpc,
    type : "singleton",

    construct : function() {
        this.base(arguments);
        this.set({
            timeout     : 15000,
            url         : 'jsonrpc/',
            serviceName : '<%= $p->{name} %>'
        });
    }
});

