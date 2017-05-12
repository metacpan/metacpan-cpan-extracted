
function notification_message(id) {
	this.id = id;
	this.m_interval = 20000;
	this.m_intervalID = 0;

	this.init = function() {
		this.get_status();
		this.start_timer();
	}

	this.get_status = function() {
		console.log("get status ...");
		$.ajax({
			url: "/notification_message",
			context: this,
			dataType: "json",
			success: function(data) {
				this.set_status(data.message);
			}
		});
	}

	this.set_status = function(status) {
		console.log("status: " + status);
	   $(this.id).text(status);
	}

	this.start_timer = function(interval) {
		if (interval) {
			this.m_interval = interval;
		}
		else {
			interval = this.m_interval;
		}

		console.log("start timer: " + interval);

		this.m_intervalID = setInterval(
				(function(self) {
					return function() {
						self.get_status();
					}
				})(this), interval);
	}

	this.stop_timer = function() {
		console.log("stop timer");
		clearInterval(this.m_intervalID);
	}
}