import QtQuick 2.0
import utils.Test 1.0

/*!
    \qmlclass TestComponent
    \brief A test component.
*/
Rectangle {
    id: testComponent

    function foo() {
        console.log("Foo!");
    }

    function bar(msg) {
        var i, line;
        line = msg + i;
        console.log(line);
    }
    
    property string name: "Test Name"
    signal yell(string what)

    clip: true
    color: "#cc000000"
    border.width: 1
    border.color: "#aaaaaaaa"
    visible: width > 0

    onVisibleChanged: {
        console.log("Visibility = " + visible);
    }
    Component.onCompleted: foo()

    MouseArea {
        anchors.fill: parent
    }
}
