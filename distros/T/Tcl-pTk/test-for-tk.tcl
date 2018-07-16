if {![catch {package require Tk}]} {
    puts {ok1}
    puts "TclVersion $tcl_version"
}
if {![catch {package require Tix}]} {
    puts {ok_Tix}
}
exit
