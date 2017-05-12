puts "tclsh=[info nameofexecutable]"
set libdir [info library]
set dirs [list \
	      [file dirname $libdir] \
	      [file dirname [file dirname $libdir]] \
	      [file join [file dirname [file dirname [info nameofexe]]] lib] \
	     ]
foreach dir $dirs {
    if {[file exists [file join $dir tclConfig.sh]]} {
	puts "tclConfig.sh=[file join $dir tclConfig.sh]"
	break
    }
}
puts "tcl_library=$libdir"
puts "tcl_version=$tcl_version"
