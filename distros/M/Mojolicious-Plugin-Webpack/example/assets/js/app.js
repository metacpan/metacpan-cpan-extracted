import '../css/css-example.css'
import '../sass/scss-example.scss'

import Vue from 'vue'
import App from './App.vue'

window.addEventListener("load", function() {
  new Vue({
    el: '#vue_app',
    render: h => h(App)
  })
});

console.log("Hey!")
