/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
var app = {
    // Application Constructor
    initialize: function () {
        this.bindEvents();
    },

    // Bind Event Listeners
    // Bind any events that are required on startup. Common events are:
    // 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: function () {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },

    // deviceready Event Handler
    // The scope of 'this' is the event. In order to call the 'receivedEvent'
    // function, we must explicitly call 'app.receivedEvent(...);'
    onDeviceReady: function () {
		// window.SoftInputMode.get(function(mode) {
		// 	alert(mode);

		// 	window.SoftInputMode.set('adjustNothing');

		// 	window.SoftInputMode.get(function(mode) {
		// 		alert(mode);
		// 	});
		// });

        app.setupPush();
    },

    // Update DOM on a Received Event
    receivedEvent: function (id) {},

    setupPush: function () {
        var push = PushNotification.init({
            "browser": {},
            "android": {},
            "ios": {
                "sound": true,
                "vibration": true,
                "badge": true
            },
            "windows": {}
        });

        // subscribe to topic
        push.subscribe('all', function () {},
        function (error) {
            alert("push error: " + error);
        });

        push.on('registration', function (data) {
            var oldRegId = localStorage.getItem('registrationId');

            if (oldRegId !== data.registrationId) {

                // save new registration ID
                localStorage.setItem('registrationId', data.registrationId);

                // Post registrationId to your app server as the value has changed
            }
        });

        push.on('error', function (e) {
            alert("push error: " + e.message);
        });

        push.on('notification', function (data) {
            Ext.fireEvent('pushNotification', data);

            // navigator.notification.alert(
            // data.message, // message
            // null, // callback
            // data.title, // title
            // 'Ok' // buttonName
            // );
        });
    }
};
