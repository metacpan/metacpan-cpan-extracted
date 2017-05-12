% my $p = shift;
/* ************************************************************************
   Copyright: <%= $p->{year} %> <%= $p->{fullName} %>
   License:   ???
   Authors:   <%= $p->{fullName} %> <<%= $p->{email} %>>
 *********************************************************************** */

/**
 * Main application class.
 */
qx.Class.define("<%= $p->{name} %>.Application", {
    extend : qx.application.Standalone,

    members : {
        /**
         * Launch the application.
         *
         * @return {void}
         */
        main : function() {
            // Call super class
            this.base(arguments);

            // Enable logging in debug variant
            if (qx.core.Environment.get("qx.debug")) {
                // support native logging capabilities, e.g. Firebug for Firefox
                qx.log.appender.Native;

                // support additional cross-browser console. Press F7 to toggle visibility
                qx.log.appender.Console;
            }

            var root = this.getRoot();
            var layout = new qx.ui.layout.Grid(10, 20)
            var grid = new qx.ui.container.Composite(new qx.ui.layout.Grid(10, 20));
            root.add(grid, {
                left   : 20,
                top    : 20,
                right  : 20,
                bottom : 20
            });

            var rpc = <%= $p->{name} %>.data.RpcService.getInstance();

            /** Server Exception **************************************/
            grid.add(new qx.ui.basic.Label('Server Response:'),{ row: 0,column: 0});
            var serverException = new qx.ui.form.TextField().set({readOnly: true});
            grid.add(serverException,{row:0,column:1});

            /** Ping Button ****************************************/
            var pingButton = new qx.ui.form.Button("PingTest");
            grid.add(pingButton,{row: 1,column: 0});
            var pingText = new qx.ui.form.TextField();
            grid.add(pingText,{row: 1,column: 1});
            var pingResponse = new qx.ui.form.TextField().set({readOnly: true});
            grid.add(pingResponse,{row: 1,column: 2});

            pingButton.addListener('execute',function(){
                rpc.callAsync(function(data,exc) {
                    if (exc){
                        serverException.setValue('ERROR:' + exc.message + ' (' + exc.code +')');
                        return;
                    }
                    pingResponse.setValue(data);
                },'ping',pingText.getValue());
            });

            /** Uptime ****************************************/
            grid.add(new qx.ui.basic.Label('Uptime:'),{ row: 2,column: 0});
            var uptimeText = new qx.ui.form.TextField().set({ readOnly: true});
            grid.add(uptimeText,{row: 2,column: 1});
            var timer = new qx.event.Timer(10000);
            timer.addListener('interval',function(){
                rpc.callAsync(function(data,exc) {
                    if (exc){
                        serverException.setValue('ERROR:' + exc.message + ' (' + exc.code +')');
                        return;
                    }
                    uptimeText.setValue(data);
                },'getUptime');
            });
			timer.start();
            /** Trigger Exception ****************************************/
            var exButton = new qx.ui.form.Button("ExceptionTest");
            grid.add(exButton,{row: 3,column: 0});
            var exText = new qx.ui.form.TextField('Sample Exception');
            grid.add(exText,{row: 3,column: 1});
            var exCode = new qx.ui.form.TextField('343');
            grid.add(exCode,{row: 3,column: 2});

            exButton.addListener('execute',function(){
                rpc.callAsync(function(data,exc) {
                    if (exc){
                        serverException.setValue('ERROR:' + exc.message + ' (' + exc.code +')');
                        return;
                    }
                },'makeException',{message: exText.getValue(), code: exCode.getValue()});
            });
        }
    }
});

