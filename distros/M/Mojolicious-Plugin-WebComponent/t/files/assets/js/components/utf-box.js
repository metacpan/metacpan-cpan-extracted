// café € in the script file
customElements.define('utf-box', class extends HTMLElement {
    constructor() {
        super();
        this.label = 'café €';
        const shadowRoot = this.attachShadow({mode: 'open'});
        let tmpl;
        shadowRoot.appendChild(tmpl.content.cloneNode(true));
    }
});
