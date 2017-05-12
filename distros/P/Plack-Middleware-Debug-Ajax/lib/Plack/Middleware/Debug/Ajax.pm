use strict;
use warnings;

package Plack::Middleware::Debug::Ajax;
{
  $Plack::Middleware::Debug::Ajax::VERSION = '0.02';
}

use parent 'Plack::Middleware::Debug::Base';

use Plack::Util::Accessor qw(log_limit);

=head1 NAME

Plack::Middleware::Debug::Ajax - Show log of ajax requests/responses

=head1 VERSION

version 0.02

=head1 SYNOPSIS

To activate this panel:

    builder {
         enable 'Debug', panels =>
               [ 
                  qw(Parameters Memory),
                  [ 'Ajax',
                     log_limit => 100,
                  ]
               ];
         $app;
   }

If you're using Dancer, you can enable the panel via your config.yml:

   plack_middlewares:
     -
       - Debug
       - panels
       -
         - Parameters
         - Memory
         - Ajax


=head1 DESCRIPTION

Adds a debug panel that logs ajax requests and responses through jQuery, as
they happen. Only ajax requests that go through jQuery are logged, because the
logging relies on jQuery's global event handlers. If you make an ajax call with
global set to false, the event won't be logged:

   $.ajax({
      // ...
      global: false,
   });

You could use this feature to selectively log messages, if you don't make use
of global ajax event handlers elsewhere.

Note that ajax events are logged as they happen, so responses won't necessarily
appear directly above their respective requests. Events are shown newest first.

=head1 SETTINGS

=over 4

=item log_limit

Limit the number of logged ajax requests and responses to the specified number.
When the log exceeds this size, the oldest items are deleted to make room for
new items. The default limit is 50, to avoid hogging memory with large
responses.

=back

=head1 STANDALONE DEMO

There is a complete standalone demo of the Ajax panel in the source of this
distribution. To run the demo, download the tarball for this distribution,
extract it, cd into it, and run:

   $ plackup sample/app.psgi

Then point your browser to:
   
   http://0:5000/

And play around with it.

=head1 JQUERY VERSIONS

Requires jQuery 1.4 or later for full functionality, and has been tested with
the following versions:

=over 4

=item 1.9.1

=item 1.8.3

=item 1.6.4

=item 1.5.1

=item 1.4.1

=back

It mostly works with jQuery 1.1 and greater, and doesn't work at all with
jQuery 1.0.

=head1 BUGS

Report any bugs via F<http://rt.cpan.org>. Pull requests welcome on github:
F<http://github.com/doublecreations/plack-middleware-debug-ajax/>

=head1 AUTHOR

Vincent Launchbury <vincent@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2013 Vincent Launchbury

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Plack::Middleware::Debug>

=cut

sub run {
   my ($self, $env, $panel) = @_;

   ##
   ## Settings
   ##

   my $log_limit = $self->log_limit || 50;

   ##
   ## Set titles
   ##

   $panel->title("Ajax Log");
   $panel->nav_title("Ajax Log");
   $panel->nav_subtitle("Live jQuery logging");


   ##
   ## Table for our panel
   ##

   my $status_table = $self->render_list_pairs(
      [ "Status" => "jQuery not present, or document not yet loaded" ],
   );


   ##
   ## Javascript/CSS/HTML
   ##

   my $id = $panel->dom_id;
   $panel->content(<<"EOF");
      <script type="text/javascript">
         // If we have jQuery
         if (typeof jQuery != 'undefined') {
            // On load
            \$(function() {

               // Log an ajax request/response
               function logAjax(data) {
                  \$('#${id}-ajaxTable > tbody').prepend(
                     \$('<tr>').append(
                        \$('<td>').append(data.type),
                        \$('<td>').append(\$('<textarea>').val(data.request)),
                        \$('<td>').append(\$('<textarea>').val(data.response))
                     ).css("background-color", data.color)
                  );

                  // Trim log (0-indexed)
                  \$('#${id}-ajaxTable > tbody > tr:eq($log_limit)').remove();
                  \$('#${id}-ajaxTable > tbody > tr:gt($log_limit)').remove();
               }

               // Make a table
               function mk_table(header, rows) {
                   var table = "<table><tr>";
                   \$(header).each(function(k, v) {
                       table += "<th>"+v+"</th>";
                   })
                   table += "</tr>";

                   \$(rows).each(function() {
                       table += "<tr>";
                       \$(this).each(function(k , v) {
                           table += "<td>"+v+"</td>";
                       })
                       table += "</tr>";                 
                   })
                   table += "</table>";
                   return table;
               }

               // For GET ajax requests we want to move the parameters to data
               // so we can display long requests in a textarea
               function move_get_params_to_data(settings) {
                  var obj = new Object();
                  obj.url = settings.url;
                  obj.data = settings.data;

                  if (settings.type == "GET") {
                     var pieces = settings.url.split('?');
                     obj.url = pieces.shift();
                     obj.data = "GET paramaters: " + pieces.join('&');
                  }
                  return obj;
               }

               // On every request
               \$(document).ajaxSend(function(event, xhr, settings) {
                  var url_and_data = move_get_params_to_data(settings);
                  logAjax({
                     type: mk_table(
                              [ "Attr", "Value" ],
                              [
                                 [ "Type:", "Ajax Request" ],
                                 [ "Date:", new Date() ],
                                 [ "URL:", url_and_data.url ],
                                 [ "Method:", settings.type ],
                                 [ "Async:", settings.async ]
                              ]
                            ),
                     request: url_and_data.data,
                     response: "",
                     color: "#EBFCFA"
                  });
               });

               // On every success
               \$(document).ajaxSuccess(function(event, xhr, settings) {
                  var url_and_data = move_get_params_to_data(settings);
                  logAjax({
                     type: mk_table(
                              ["Attr",    "Value"],
                              [ 
                                 [ "Type:",   "Ajax Success" ],
                                 [ "Date:",   new Date() ],
                                 [ "URL:",    url_and_data.url],
                                 [ "Method:", settings.type],
                                 [ "Status:", xhr.status]
                              ]
                           ),
                     request: url_and_data.data,
                     response: xhr.responseText,
                     color: "#D6FFD1"
                  });
               });

               // On every failure
               \$(document).ajaxError(function(event, xhr, settings, exception) {
                  var url_and_data = move_get_params_to_data(settings);
                  logAjax({
                     type: mk_table(
                              ["Attr",    "Value"],
                              [
                                 [ "Type:",   "Ajax Error" ],
                                 [ "Date:",   new Date() ],
                                 [ "URL:",    url_and_data.url],
                                 [ "Method:", settings.type],
                                 [ "Status:", xhr.status]
                              ]
                           ),
                     request: url_and_data.data,
                     response: exception,
                     color: "#FAC0CE"
                  });
               });

               // Update status row
               \$('#${id} table:first tbody tr:first td:last').text(
                  "jQuery found, listening for ajax events."
               );
            });
         }
      </script>
      <style type="text/css">
         /* attr/val table */
         #${id}-ajaxTable table {
            width: 100%;
            height: 90%;
            min-height: 100px;
            margin: 10px 0;
            padding:0;
         }
         #${id}-ajaxTable table td:first-child,
         #${id}-ajaxTable table th:first-child {
            width:20%;
         }
         #${id}-ajaxTable table th {
            text-align:left !important;
         }
         #${id}-ajaxTable tbody > tr > td{
            height: 100%;
         }

         /* Text area */
         #${id}-ajaxTable textarea {
            width: 100%;
            height: 90%;
            margin: 10px 0;
            padding:0;
            min-height: 100px;
            border: 1px solid #ccc;
         }

         \@media (max-width: 768px) {
            /* Hide Type/Request/Response header */
            #${id}-ajaxTable > thead > tr {
               display:none;
            }
            /* But show info anyway */
            #${id}-ajaxTable > tbody > tr > td:nth-child(2):before {
               content: "Request:";
            }
            #${id}-ajaxTable > tbody > tr > td:nth-child(3):before {
               content: "Response:";
            }

            /* Display as blocks so <td>'s show below each other */
            #${id}-ajaxTable > tbody > tr,
            #${id}-ajaxTable > tbody > tr > td {
               display: block;
               text-align: left;
            }

            /* Show some dividers */
            #${id}-ajaxTable > tbody > tr {
               border-top: 1px solid black;
               border-bottom: 1px solid black;
               padding-bottom: 10px;
               margin-bottom: 20px;
            }
         }
         
      </style>
      $status_table
      <table id="${id}-ajaxTable">
         <thead>
            <tr>
               <th>Type</th>
               <th>Request</th>
               <th>Response</th>
            </tr>
         <thead>
         <tbody>
         </tbody>
      </table>
EOF
}

1;
