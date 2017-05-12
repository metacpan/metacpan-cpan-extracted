<div class="navbar navbar-inverse navbar-fixed-top">
   <div class="navbar-inner">
      <div class="container">
          <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="brand" href="#">Monitoring::Spooler</a>
          <div class="nav-collapse collapse">
            <ul class="nav">
               <li><a href="?rm=overview">Overview</a></li>
            [% FOREACH group IN groups %]
              <li class="dropdown[% IF group.key == group_id %] active[% END %]">
                <a href="#" class="dropdown-toggle" data-toggle="dropdown">[% group.value.name %] <b class="caret"></b></a>
                <ul class="dropdown-menu">
                  <li><a href="?rm=show_group&group_id=[% group.key %]#messages">Message Queue</a></li>
                  <li><a href="?rm=show_group&group_id=[% group.key %]#order">Notification Queue</a></li>
                  <li><a href="?rm=show_group&group_id=[% group.key %]#windows">Notification Windows</a></li>
                </ul>
              </li>
              [% END %]
              <li><a href="?rm=list_procs">Running Processes</a></li>
            </ul>
          </div><!--/.nav-collapse -->
      </div>
    </div>
</div>

