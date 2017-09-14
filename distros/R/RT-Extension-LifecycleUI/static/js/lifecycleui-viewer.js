jQuery(function () {
    function Viewer (container) {
        this.width  = 809;
        this.height = 500;
        this.statusCircleRadius = 35;
        this.gridSize = 10;
        this.padding = this.statusCircleRadius * 2;
    };

    Viewer.prototype.createScale = function (size, padding) {
        return d3.scaleLinear()
                 .domain([0, 10000])
                 .range([padding, size - padding]);
    };

    Viewer.prototype.gridScale = function (v) { return Math.round(v/this.gridSize) * this.gridSize };
    Viewer.prototype.xScale = function (x) { return this.gridScale(this._xScale(x)) };
    Viewer.prototype.yScale = function (y) { return this.gridScale(this._yScale(y)) };
    Viewer.prototype.xScaleZero = function (x) { return this.gridScale(this._xScaleZero(x)) };
    Viewer.prototype.yScaleZero = function (y) { return this.gridScale(this._yScaleZero(y)) };
    Viewer.prototype.xScaleInvert = function (x) { return Math.floor(this._xScale.invert(x)) };
    Viewer.prototype.yScaleInvert = function (y) { return Math.floor(this._yScale.invert(y)) };
    Viewer.prototype.xScaleZeroInvert = function (x) { return Math.floor(this._xScaleZero.invert(x)) };
    Viewer.prototype.yScaleZeroInvert = function (y) { return Math.floor(this._yScaleZero.invert(y)) };

    Viewer.prototype.addZoomBehavior = function () {
        var self = this;
        self._zoom = d3.zoom()
                       .scaleExtent([.3, 2])
                       .on("zoom", function () { self.didZoom() });
        self.svg.call(self._zoom);
    };

    Viewer.prototype.didZoom = function () {
        this._currentZoom = d3.event.transform;
        this.transformContainer.attr("transform", d3.event.transform);
    };

    Viewer.prototype.zoomScale = function (scaleBy, animated) {
        if (animated) {
            this.svg.transition()
                    .duration(350)
                    .call(this._zoom.scaleBy, scaleBy);
        }
        else {
            this.svg.call(this._zoom.scaleBy, scaleBy);
        }
    }

    Viewer.prototype.resetZoom = function (animated) {
        if (animated) {
            this.svg.transition()
                    .duration(750)
                    .call(this._zoom.transform, this._zoomIdentity);
        }
        else {
            this.svg.call(this._zoom.transform, this._zoomIdentity);
        }
    };

    Viewer.prototype.didEnterStatusNodes = function (statuses) { };
    Viewer.prototype.didEnterStatusLabels = function (labels) { };
    Viewer.prototype.didEnterTransitions = function (paths) { };
    Viewer.prototype.didEnterTextDecorations = function (labels) { };
    Viewer.prototype.didEnterPolygonDecorations = function (polygons) { };
    Viewer.prototype.didEnterCircleDecorations = function (circles) { };
    Viewer.prototype.didEnterLineDecorations = function (lines) { };

    Viewer.prototype.renderStatusNodes = function (initial) {
        var self = this;
        var statuses = self.statusContainer.selectAll("circle")
                                           .data(self.lifecycle.statusObjects(), function (d) { return d._key });

        statuses.exit()
              .classed("removing", true)
              .transition().duration(200)
                .attr("r", self.statusCircleRadius * .8)
                .remove();

        statuses.enter().append("circle")
                        .attr("r", self.statusCircleRadius)
                        .attr("data-key", function (d) { return d._key })
                        .on("click", function (d) {
                            d3.event.stopPropagation();
                            self.clickedStatus(d);
                        })
                        .call(function (statuses) { self.didEnterStatusNodes(statuses) })
                .merge(statuses)
                        .attr("cx", function (d) { return self.xScale(d.x) })
                        .attr("cy", function (d) { return self.yScale(d.y) })
                        .attr("fill", function (d) { return d.color })
                        .classed("focus", function (d) { return self.isFocused(d) })
                        .classed("focus-from", function (d) { return self.isFocusedTransition(d, true) })
                        .classed("focus-to", function (d) { return self.isFocusedTransition(d, false) });
    };

    Viewer.prototype.clickedStatus = function (d) { };
    Viewer.prototype.clickedTransition = function (d) { };
    Viewer.prototype.clickedDecoration = function (d) { };

    Viewer.prototype.truncateLabel = function (element) {
        var node = d3.select(element),
            textLength = node.node().getComputedTextLength(),
            text = node.text();
        while (textLength > this.statusCircleRadius*1.8 && text.length > 0) {
            text = text.slice(0, -1);
            node.text(text + '…');
            textLength = node.node().getComputedTextLength();
        }
    };

    Viewer.prototype.renderStatusLabels = function (initial) {
        var self = this;
        var labels = self.statusContainer.selectAll("text")
                                         .data(self.lifecycle.statusObjects(), function (d) { return d._key });

        labels.exit()
            .classed("removing", true)
            .transition().duration(200)
              .remove();

        labels.enter().append("text")
                      .attr("data-key", function (d) { return d._key })
                      .on("click", function (d) {
                          d3.event.stopPropagation();
                          self.clickedStatus(d);
                      })
                     .call(function (labels) { self.didEnterStatusLabels(labels) })
              .merge(labels)
                      .attr("x", function (d) { return self.xScale(d.x) })
                      .attr("y", function (d) { return self.yScale(d.y) })
                      .attr("fill", function (d) { return d3.hsl(d.color).l > 0.35 ? '#000' : '#fff' })
                      .text(function (d) { return d.name }).each(function () { self.truncateLabel(this) })
                      .classed("focus", function (d) { return self.isFocused(d) })
                      .classed("focus-from", function (d) { return self.isFocusedTransition(d, true) })
                      .classed("focus-to", function (d) { return self.isFocusedTransition(d, false) });
    };

    Viewer.prototype.transitionArc = function (d) {
      var from = this.lifecycle.statusObjectForName(d.from);
      var to = this.lifecycle.statusObjectForName(d.to);
      var dx = this.xScale(to.x - from.x),
          dy = this.yScale(to.y - from.y),
          dr = Math.abs(dx*6) + Math.abs(dy*6);
      return "M" + this.xScale(from.x) + "," + this.yScale(from.y) + "A" + dr + "," + dr + " 0 0,1 " + this.xScale(to.x) + "," + this.yScale(to.y);
    };

    Viewer.prototype.renderTransitions = function (initial) {
        var self = this;
        var paths = self.transitionContainer.selectAll("path")
                        .data(self.lifecycle.transitions, function (d) { return d._key });

        paths.exit()
            .classed("removing", true)
            .transition().duration(200)
              .remove();

        paths.enter().append("path")
                     .attr("data-key", function (d) { return d._key })
                     .on("click", function (d) {
                         d3.event.stopPropagation();
                         self.clickedTransition(d);
                     })
                     .call(function (paths) { self.didEnterTransitions(paths) })
              .merge(paths)
                      .attr("d", function (d) { return self.transitionArc(d) })
                      .classed("dashed", function (d) { return d.style == 'dashed' })
                      .classed("dotted", function (d) { return d.style == 'dotted' })
                      .classed("focus", function (d) { return self.isFocused(d) })
                      .classed("focus-from", function (d) { return self.isFocusedTransition(d, true) })
                      .classed("focus-to", function (d) { return self.isFocusedTransition(d, false) });
    };

    Viewer.prototype._wrapTextDecoration = function (node, text) {
        if (node.attr('data-text') == text) {
            return;
        }

        var lines = text.split(/\n/),
            lineHeight = 1.1;

        if (node.attr('data-text')) {
            node.selectAll("*").remove();
        }
        node.attr('data-text', text);

        for (var i = 0; i < lines.length; ++i) {
            node.append("tspan").attr("dy", (i+1) * lineHeight + "em").text(lines[i]);
        }
    };

    Viewer.prototype.renderTextDecorations = function (initial) {
        var self = this;
        var labels = self.decorationContainer.selectAll("text")
                         .data(self.lifecycle.decorations.text, function (d) { return d._key });

        labels.exit()
            .classed("removing", true)
            .transition().duration(200)
              .remove();

        labels.enter().append("text")
                     .attr("data-key", function (d) { return d._key })
                     .on("click", function (d) {
                         d3.event.stopPropagation();
                         self.clickedDecoration(d);
                     })
                     .call(function (labels) { self.didEnterTextDecorations(labels) })
              .merge(labels)
                      .attr("x", function (d) { return self.xScale(d.x) })
                      .attr("y", function (d) { return self.yScale(d.y) })
                      .classed("bold", function (d) { return d.bold })
                      .classed("italic", function (d) { return d.italic })
                      .classed("focus", function (d) { return self.isFocused(d) })
                      .each(function (d) { self._wrapTextDecoration(d3.select(this), d.text) })
              .selectAll("tspan")
                      .attr("x", function (d) { return self.xScale(d.x) })
                      .attr("y", function (d) { return self.yScale(d.y) })
    };

    Viewer.prototype.renderPolygonDecorations = function (initial) {
        var self = this;
        var polygons = self.decorationContainer.selectAll("polygon")
                           .data(self.lifecycle.decorations.polygon, function (d) { return d._key });

        polygons.exit()
            .classed("removing", true)
            .transition().duration(200)
              .remove();

        polygons.enter().append("polygon")
                     .attr("data-key", function (d) { return d._key })
                     .on("click", function (d) {
                         d3.event.stopPropagation();
                         self.clickedDecoration(d);
                     })
                     .call(function (polygons) { self.didEnterPolygonDecorations(polygons) })
              .merge(polygons)
                     .attr("stroke", function (d) { return d.renderStroke ? d.stroke : 'none' })
                     .classed("dashed", function (d) { return d.strokeStyle == 'dashed' })
                     .classed("dotted", function (d) { return d.strokeStyle == 'dotted' })
                     .attr("fill", function (d) { return d.renderFill ? d.fill : 'none' })
                     .attr("transform", function (d) { return "translate(" + self.xScale(d.x) + ", " + self.yScale(d.y) + ")" })
                     .attr("points", function (d) {
                         return jQuery.map(d.points, function(p) {
                             return [self.xScaleZero(p.x),self.yScaleZero(p.y)].join(",");
                         }).join(" ");
                     })
                    .classed("focus", function (d) { return self.isFocused(d) })
    };

    Viewer.prototype.renderCircleDecorations = function (initial) {
        var self = this;
        var circles = self.decorationContainer.selectAll("circle.decoration")
                           .data(self.lifecycle.decorations.circle, function (d) { return d._key });

        circles.exit()
            .classed("removing", true)
            .transition().duration(200)
              .remove();

        circles.enter().append("circle")
                     .classed("decoration", true)
                     .attr("data-key", function (d) { return d._key })
                     .on("click", function (d) {
                         d3.event.stopPropagation();
                         self.clickedDecoration(d);
                     })
                     .call(function (circles) { self.didEnterCircleDecorations(circles) })
              .merge(circles)
                     .attr("stroke", function (d) { return d.renderStroke ? d.stroke : 'none' })
                     .classed("dashed", function (d) { return d.strokeStyle == 'dashed' })
                     .classed("dotted", function (d) { return d.strokeStyle == 'dotted' })
                     .attr("fill", function (d) { return d.renderFill ? d.fill : 'none' })
                     .attr("cx", function (d) { return self.xScale(d.x) })
                     .attr("cy", function (d) { return self.yScale(d.y) })
                     .attr("r", function (d) { return d.r })
                     .classed("focus", function (d) { return self.isFocused(d) })
    };

    Viewer.prototype.renderLineDecorations = function (initial) {
        var self = this;
        var lines = self.decorationContainer.selectAll("line")
                           .data(self.lifecycle.decorations.line, function (d) { return d._key });

        lines.exit()
            .classed("removing", true)
            .transition().duration(200)
              .remove();

        lines.enter().append("line")
                     .attr("data-key", function (d) { return d._key })
                     .on("click", function (d) {
                         d3.event.stopPropagation();
                         self.clickedDecoration(d);
                     })
                     .call(function (lines) { self.didEnterLineDecorations(lines) })
              .merge(lines)
                     .classed("dashed", function (d) { return d.style == 'dashed' })
                     .classed("dotted", function (d) { return d.style == 'dotted' })
                     .attr("transform", function (d) { return "translate(" + self.xScale(d.x) + ", " + self.yScale(d.y) + ")" })
                     .attr("x1", function (d) { return self.xScaleZero(d.points[0].x) })
                     .attr("y1", function (d) { return self.yScaleZero(d.points[0].y) })
                     .attr("x2", function (d) { return self.xScaleZero(d.points[1].x) })
                     .attr("y2", function (d) { return self.yScaleZero(d.points[1].y) })
                     .classed("focus", function (d) { return self.isFocused(d) })
                     .attr("marker-start", function (d) { return d.startMarker == 'none' ? undefined : "url(#line_marker_" + d.startMarker + ")" })
                     .attr("marker-end", function (d) { return d.endMarker == 'none' ? undefined : "url(#line_marker_" + d.endMarker + ")" })
    };

    Viewer.prototype.renderDecorations = function (initial) {
        this.renderPolygonDecorations(initial);
        this.renderCircleDecorations(initial);
        this.renderLineDecorations(initial);
        this.renderTextDecorations(initial);
    };

    Viewer.prototype.renderDisplay = function (initial) {
        this.renderTransitions(initial);
        this.renderStatusNodes(initial);
        this.renderStatusLabels(initial);
        this.renderDecorations(initial);
    };

    Viewer.prototype.centerOnItem = function (item, animated) {
        var rect = this.svg.node().getBoundingClientRect();
        var scale = this._zoomIdentityScale;
        var x = rect.width/2 - this.xScale(item.x) * scale;
        var y = rect.height/2 - this.yScale(item.y) * scale;
        this._zoomIdentity = d3.zoomIdentity.translate(x, y).scale(this._zoomIdentityScale);
        this.resetZoom(animated);
    };

    Viewer.prototype.defocus = function () {
        this._focusItem = null;
        this.svg.classed("has-focus", false)
                .attr('data-focus-type', undefined);
    };

    Viewer.prototype.focusItem = function (d) {
        this.defocus();

        this._focusItem = d;
        this.svg.classed("has-focus", true)
                .attr('data-focus-type', d._type);
    };

    Viewer.prototype.focusOnStatus = function (statusName, center, animated) {
        if (!statusName) {
            return;
        }

        var meta = this.lifecycle.statusObjectForName(statusName);
        this.focusItem(meta);

        if (center) {
            this.centerOnItem(meta, animated)
        }
    };

    Viewer.prototype.isFocused = function (d) {
        if (!this._focusItem) {
            return false;
        }
        return this._focusItem._key == d._key;
    };

    Viewer.prototype.isFocusedTransition = function (d, isFrom) {
        if (!this._focusItem) {
            return false;
        }

        if (d._type == 'status') {
            if (this._focusItem._type == 'status') {
                if (isFrom) {
                    return this.lifecycle.hasTransition(d.name, this._focusItem.name);
                }
                else {
                    return this.lifecycle.hasTransition(this._focusItem.name, d.name);
                }
            }
            else if (this._focusItem._type == 'transition') {
                if (isFrom) {
                    return this._focusItem.from == d.name;
                }
                else {
                    return this._focusItem.to == d.name;
                }
            }
        }
        else if (d._type == 'transition') {
            if (this._focusItem._type == 'status') {
                if (isFrom) {
                    return d.to == this._focusItem.name;
                }
                else {
                    return d.from == this._focusItem.name;
                }
            }
        }

        return false;
    };

    Viewer.prototype.initializeViewer = function (node, name, config, focusStatus) {
        var self = this;

        self.container = jQuery(node);
        self.svg       = d3.select(node).select('svg');

        self.transformContainer  = self.svg.select('g.transform');
        self.transitionContainer = self.svg.select('g.transitions');
        self.statusContainer     = self.svg.select('g.statuses');
        self.decorationContainer = self.svg.select('g.decorations');

        self._xScale = self.createScale(self.width, self.padding);
        self._yScale = self.createScale(self.height, self.padding);
        self._xScaleZero = self.createScale(self.width, 0);
        self._yScaleZero = self.createScale(self.height, 0);

        // zoom in a bit, but not too much
        var scale = self.svg.node().getBoundingClientRect().width / self.width;
        scale = scale ** .6;

        self._zoomIdentityScale = scale;
        self._zoomIdentity = self._currentZoom = d3.zoomIdentity.scale(self._zoomIdentityScale);

        self.lifecycle = new RT.Lifecycle(name);
        self.lifecycle.initializeFromConfig(config);

        self.addZoomBehavior();

        self.focusOnStatus(focusStatus, true, false);

        self.renderDisplay(true);

        self.container.on('click', 'button.zoom-in', function (e) {
            e.preventDefault();
            self.zoomScale(1.25, true);
        });

        self.container.on('click', 'button.zoom-out', function (e) {
            e.preventDefault();
            self.zoomScale(.75, true);
        });

        self.container.on('click', 'button.zoom-reset', function (e) {
            e.preventDefault();
            self.resetZoom(true);
        });
    };

    RT.LifecycleViewer = Viewer;
});

