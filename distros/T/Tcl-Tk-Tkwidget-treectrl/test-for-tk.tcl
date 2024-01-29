if {![catch {package require Tk}]} {
    puts {ok1}
    puts $tcl_version
}
if {![catch {package require snit}]} {
    puts {ok2}
}
# detect tklib existence ('cursor' is a package in tklib)
if {![catch {package require cursor}]} {
    puts {ok3}
}
if {![catch {package require tile}]} {
    puts {ok4}
}
exit
