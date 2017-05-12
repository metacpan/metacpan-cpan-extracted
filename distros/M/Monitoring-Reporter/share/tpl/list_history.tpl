[% USE date(format = '%d.%m.%y %H:%M:%S', locale = 'de_DE') %]
<!doctype html>  
<html lang="en">
<head>
  <meta charset="utf-8">

  <!-- Always force latest IE rendering engine (even in intranet) & Chrome Frame 
       Remove this if you use the .htaccess -->
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">

  <title>[% title %]</title>
  <meta name="description" content="[% product %] Web Management Interface">
  <meta name="author" content="[% product %] by Dominik Schulz">
  <meta http-equiv="refresh" content="[% refresh %]" />

  <!--  Mobile viewport optimized: j.mp/bplateviewport -->
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

   <link href="css/bootstrap.min.css" rel="stylesheet">
   <style type="text/css">
      body {
         padding-top: 60px;
         padding-bottom: 40px;
      }
   </style>
   <link href="css/bootstrap-responsive.min.css" rel="stylesheet">
   <link rel="stylesheet" type="text/css" href="css/default.css" media="all" />
</head>

<body onload="setTimeout(function(){ alert('No refresh for 90 minutes!'); }, 90 * 60 * 1000);">
      <div class="container">
        <h1>[% title %]</h1>
        [% IF triggers.size > 0 %]
        <table clasS="table table-striped">
          <thead>
            <tr>
              <td><b>Severity</b></td>
              <td><b>Date</b></td>
              <td><b>Host</b></td>
              <td><b>Name</b></td>
            </tr>
          </thead>
          <tbody>
        [% FOREACH trigger IN triggers %]
            <tr>
              <td>
                <button class="btn [% trigger.severity | sev2btn %]">[% trigger.severity | ucfirst %]</button>
              </td>
              <td>[% trigger.clock | localtime %]</td>
              <td>[% trigger.host %]</td>
              <td>[% trigger.description %]</td>
            </tr>
        </div>
        [% END %]
          </tbody>
          <tfoot>
          </tfoot>
        </table>
        [% ELSE %]
        <div class="allgreen">No errors. All good. Relax.<br /><div class="smiley">&#x263A;</div></div>
        [% END %]
        <br />
        <div class="lastupdate">
                Last update: [% date.format %]
        </div>
      </div><!-- /container -->
  <script src="js/jquery-2.0.1.min.js"></script>
  <script src="js/bootstrap.min.js"></script>
</body>
</html>
