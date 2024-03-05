// Extend generic HTMLElement interface
class MyComponent extends HTMLElement {
    constructor() {
        super();
        const shadowRoot = this.attachShadow({mode: 'open'});
        // tmpl variable is generated server side if not provided as a local variable
        // the tmpl variable will be replaced server side by the Mojolicious WebComponent
        // plugin
        let tmpl;
        shadowRoot.appendChild(tmpl.content.cloneNode(true));
    }

    // component attributes
    static get observedAttributes() {
        return ['message'];
    }

    connectedCallback() {
        const {shadowRoot} = this;
    }

    // attribute change
    attributeChangedCallback(property, oldValue, newValue) {
        if (oldValue === newValue) return;
        this[property] = newValue;
        console.log(property, oldValue, newValue)
    }

    set message(val) {
        const {shadowRoot} = this;
        let msg = shadowRoot.querySelector('#message')
        msg.innerHTML = val
    }
}

customElements.define('my-component', MyComponent);
