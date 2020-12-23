import Hello from './Шаблон №1.html.vue'

export default {
  name: 'HelloWorld',
  props: {
    msg: String
  },
  render:Hello.render,
  data(){
    return {
      "plugins":[
        {
          "name":'babel',
          "href":'https://github.com/vuejs/vue-cli/tree/dev/packages/%40vue/cli-plugin-babel',
        },
        {
          "name":'eslint',
          "href":"https://github.com/vuejs/vue-cli/tree/dev/packages/%40vue/cli-plugin-eslint",
        },
      
      ],
      "essential":[
        {"name":'Базовая документация', "href":"https://vuejs.org",},
        {"name":'Forum', "href":"https://forum.vuejs.org",},
        {"name":'Community Chat', "href":"https://chat.vuejs.org",},
        {"name":'Twitter', "href":"https://twitter.com/vuejs",},
        {"name":'News', "href":"https://news.vuejs.org",},
        
      ],
      "ecosystem":[
        {"name":'vue-router', "href":"https://router.vuejs.org",},
        {"name":'vuex', "href":"https://vuex.vuejs.org",},
        {"name":'vue-devtools', "href":"https://github.com/vuejs/vue-devtools#vue-devtools",},
        {"name":'vue-loader', "href":"https://vue-loader.vuejs.org",},
        {"name":'awesome-vue',"href":"https://github.com/vuejs/awesome-vue",},
      ],
      
    };
    
  }
}